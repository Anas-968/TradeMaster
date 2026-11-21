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

## Human support chat setup

1. In Supabase Dashboard, enable **Anonymous Sign-Ins** under Authentication settings.
2. Run [`migrations/20261121_live_support_chat.sql`](migrations/20261121_live_support_chat.sql) in the SQL Editor.
3. Customers can open **Live Chat Support** from the home screen without an account. Signed-in administrators can reply from the **Support** tab in the admin panel.

Guest conversations are attached to that device's anonymous session. Clearing app data removes access to the guest session and its conversation.

## Push notifications

The app registers signed-in devices in `public.device_tokens`. The database migration sends load and support-message events to the `send-notification` Edge Function. The function sends Firebase Cloud Messaging (FCM) pushes to all of a user's registered devices. It sends notifications for new loads to active drivers, accepted/delivered status changes to the load's trader, and customer support messages to administrators whose trusted `app_metadata.is_admin` claim is `true`.

1. Make sure Firebase Cloud Messaging is enabled for the Firebase project used by the app. Create a Firebase service account key with permission to send FCM messages. Keep its JSON private; never commit it or put it in the Flutter app. iOS also requires an APNs authentication key configured in Firebase.
2. In Supabase Dashboard, open **Edge Functions → Secrets** and add `FIREBASE_SERVICE_ACCOUNT_JSON` with the full contents of the Firebase service account JSON file, and `NOTIFICATION_HOOK_SECRET` with a long random value. Then deploy the function from the project folder:

   ```powershell
   supabase functions deploy send-notification --no-verify-jwt
   ```

   `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are provided to the Edge Function by Supabase. The function endpoint is `https://bqerwxkixqgiofndeocy.supabase.co/functions/v1/send-notification` for this project.
3. In Supabase Dashboard, open **Vault** and add two secrets. Name the first `notification_function_url` and set its value to that function endpoint. Name the second `notification_hook_secret` and set its value to the same random value used for `NOTIFICATION_HOOK_SECRET` above.
4. Run [`migrations/20261122_push_notifications.sql`](migrations/20261122_push_notifications.sql) in the Supabase SQL Editor. It creates the token table, secure token-registration RPC, and database triggers. The Vault secrets must exist before the triggers can send events.
5. Run `flutter pub get`, then rebuild and reinstall the app on each device. Users must allow notifications and sign in at least once on each device so the FCM token is registered.

The database hook is authenticated with the shared Vault secret. Rotate it in both the Edge Function secrets and Vault together if it is changed. The support notification is only sent when the message sender is the conversation owner, so admin replies do not alert the admins.
