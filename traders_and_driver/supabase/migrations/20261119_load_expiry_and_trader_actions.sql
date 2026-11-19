-- Apply this migration to an existing Supabase project.
alter table public.loads add column if not exists expires_at timestamptz;
update public.loads set expires_at = created_at + interval '90 days' where expires_at is null;
alter table public.loads alter column expires_at set default (now() + interval '90 days');
alter table public.loads alter column expires_at set not null;
create index if not exists loads_expiry_idx on public.loads(expires_at);

create or replace function public.set_load_expiry()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.expires_at := now() + interval '90 days';
  return new;
end;
$$;
drop trigger if exists loads_set_expiry on public.loads;
create trigger loads_set_expiry before insert on public.loads
  for each row execute function public.set_load_expiry();

create or replace function public.delete_trader_load(p_load_id bigint)
returns bigint language plpgsql security definer set search_path = '' as $$
declare deleted_id bigint;
begin
  if auth.uid() is null or not exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.user_type = 'Trader' and p.is_active
  ) then raise exception 'Only active traders may delete loads'; end if;
  delete from public.loads
    where id = p_load_id and trader_id = auth.uid() and status in ('Available', 'Delivered')
    returning id into deleted_id;
  if deleted_id is null then raise exception 'Only your available or delivered loads can be deleted'; end if;
  return deleted_id;
end;
$$;
revoke all on function public.delete_trader_load(bigint) from public;
grant execute on function public.delete_trader_load(bigint) to authenticated;

create or replace function public.get_load_driver_details(p_load_id bigint)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare driver_details jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select jsonb_build_object(
    'full_name', p.full_name,
    'phone', p.phone,
    'accepted_at', l.accepted_at
  ) into driver_details
  from public.loads l
  join public.profiles p on p.id = l.driver_id
  where l.id = p_load_id and l.trader_id = auth.uid();
  if driver_details is null then raise exception 'Driver details are not available for this load'; end if;
  return driver_details;
end;
$$;
revoke all on function public.get_load_driver_details(bigint) from public;
grant execute on function public.get_load_driver_details(bigint) to authenticated;

create extension if not exists pg_cron with schema pg_catalog;
do $$
declare existing_job bigint;
begin
  select jobid into existing_job from cron.job where jobname = 'delete-expired-loads';
  if existing_job is not null then perform cron.unschedule(existing_job); end if;
  perform cron.schedule('delete-expired-loads', '0 * * * *',
    'delete from public.loads where expires_at <= now()');
end;
$$;
