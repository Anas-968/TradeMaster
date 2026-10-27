# Supabase setup

1. Open the project's Supabase dashboard and go to **SQL Editor**.
2. Run the full [`schema.sql`](schema.sql) script. It creates the profiles and loads tables, row-level security policies, the signup profile trigger, and the atomic `accept_load` function. It also backfills profiles for existing accounts.
3. Grant the administrator account trusted `app_metadata` with `is_admin: true`. From the SQL Editor, replace the phone number and run:

   ```sql
   update auth.users
   set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"is_admin":true}'::jsonb
   where phone = '+968XXXXXXXX';
   ```

4. Sign out and sign back in as that account so the refreshed access token includes the administrator claim.

The app uses `profiles.is_active` to suspend and restore accounts. A suspended account cannot post or accept loads and is sent back out at the next login. The driver claim runs through a database function that only changes an available load once. No payment processing is included.

The app's Supabase URL and anonymous key remain configured in `lib/main.dart`; use your own project's values before distributing the app.
