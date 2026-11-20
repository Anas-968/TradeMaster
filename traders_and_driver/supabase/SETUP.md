# Supabase setup

1. Open the project's Supabase dashboard and go to **SQL Editor**.
2. Run the full [`schema.sql`](schema.sql) script. It creates the profiles and loads tables, row-level security policies, the signup profile trigger, and the atomic `accept_load` function. It also backfills profiles for existing accounts.
   The schema schedules an hourly `pg_cron` job that permanently deletes loads after their 90-day expiry. For an existing database, run [`migrations/20261119_load_expiry_and_trader_actions.sql`](migrations/20261119_load_expiry_and_trader_actions.sql) in the SQL Editor instead of rerunning the full schema. Confirm the `pg_cron` extension is available in the Supabase project; the migration enables it and schedules the cleanup job.
3. Grant the administrator account trusted `app_metadata` with `is_admin: true`. From the SQL Editor, replace the phone number and run:

   ```sql
   update auth.users
   set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"is_admin":true}'::jsonb
   where phone = '+968XXXXXXXX';
   ```

4. Sign out and sign back in as that account so the refreshed access token includes the administrator claim.

The app uses `profiles.is_active` to suspend and restore accounts. A suspended account cannot post or accept loads and is sent back out at the next login. The driver claim runs through a database function that only changes an available load once. No payment processing is included.

## AI assistant setup

The in-app assistant calls the `assistant-chat` Supabase Edge Function. The function requires a signed-in user (Supabase verifies the JWT) and calls OpenAI on the server, so never put the OpenAI API key in the Flutter app.

1. In Supabase Dashboard, open **Edge Functions → Secrets** for this project and add `OPENAI_API_KEY`. Optionally add `OPENAI_MODEL` with a model enabled for your OpenAI project; the default is `gpt-4.1-mini`.
2. Install the Supabase CLI if needed, open a terminal in the `traders_and_driver` project folder, then authenticate and deploy:

   ```powershell
   supabase login
   supabase functions deploy assistant-chat
   ```

   The project reference and JWT verification setting are in [`config.toml`](config.toml). The function only accepts requests with a valid signed-in Supabase user session.
3. Open the app while signed in, then choose **AI Help** in the trader or driver navigation, or open the assistant from the home page.

The Edge Function limits requests to 20 messages, 4,000 characters per message, and 500 generated tokens. Chat history is kept in app memory only and is sent to the function for each reply.

The app's Supabase URL and anonymous key remain configured in `lib/main.dart`; use your own project's values before distributing the app.
