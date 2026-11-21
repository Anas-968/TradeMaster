-- Device tokens are only readable/writable by their owner. The push function
-- uses the service role to resolve recipients and send notifications.
create table if not exists public.device_tokens (
  token text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null default 'unknown',
  updated_at timestamptz not null default now()
);
alter table public.device_tokens enable row level security;
grant select, insert, update, delete on public.device_tokens to authenticated;
drop policy if exists "users manage their device tokens" on public.device_tokens;
create policy "users manage their device tokens" on public.device_tokens
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create or replace function public.register_device_token(p_token text, p_platform text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or length(p_token) < 20 then raise exception 'Valid signed-in device token required'; end if;
  delete from public.device_tokens where token = p_token and user_id <> auth.uid();
  insert into public.device_tokens(token, user_id, platform, updated_at)
    values (p_token, auth.uid(), coalesce(p_platform, 'unknown'), now())
  on conflict (token) do update set user_id = excluded.user_id, platform = excluded.platform, updated_at = now();
end;
$$;
revoke all on function public.register_device_token(text, text) from public;
grant execute on function public.register_device_token(text, text) to authenticated;

-- The Edge Function URL and a shared hook secret live in Supabase Vault.
create extension if not exists pg_net;
create extension if not exists supabase_vault;

create or replace function public.notify_trade_event()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  event_row jsonb;
  prior_row jsonb;
  hook_url text;
  hook_secret text;
begin
  event_row := to_jsonb(new);
  if tg_table_name = 'loads' and tg_op = 'UPDATE' then
    if new.status not in ('Accepted', 'Delivered') or new.status = old.status then return new; end if;
    prior_row := to_jsonb(old);
  elsif tg_table_name = 'loads' and tg_op = 'INSERT' then
    if new.status <> 'Available' then return new; end if;
    prior_row := null;
  elsif tg_table_name = 'support_messages' and tg_op = 'INSERT' then
    prior_row := null;
  else
    return new;
  end if;

  select decrypted_secret into hook_url from vault.decrypted_secrets where name = 'notification_function_url' limit 1;
  select decrypted_secret into hook_secret from vault.decrypted_secrets where name = 'notification_hook_secret' limit 1;
  if hook_url is null or hook_secret is null then return new; end if;

  perform net.http_post(
    url := hook_url,
    headers := jsonb_build_object('content-type', 'application/json', 'x-hook-secret', hook_secret),
    body := jsonb_build_object('table', tg_table_name, 'operation', tg_op,
      'record', event_row, 'old_record', prior_row)
  );
  return new;
end;
$$;
revoke all on function public.notify_trade_event() from public, anon, authenticated;

drop trigger if exists notify_load_insert on public.loads;
create trigger notify_load_insert after insert on public.loads
  for each row execute function public.notify_trade_event();
drop trigger if exists notify_load_status on public.loads;
create trigger notify_load_status after update of status on public.loads
  for each row execute function public.notify_trade_event();
drop trigger if exists notify_support_message on public.support_messages;
create trigger notify_support_message after insert on public.support_messages
  for each row execute function public.notify_trade_event();
