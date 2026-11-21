import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const encoder = new TextEncoder();
const base64url = (data: Uint8Array) => btoa(String.fromCharCode(...data))
  .replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
const jsonPart = (value: unknown) => base64url(encoder.encode(JSON.stringify(value)));

async function firebaseAccessToken(account: Record<string, string>) {
  const now = Math.floor(Date.now() / 1000);
  const pem = account.private_key.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, '');
  const keyBytes = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey('pkcs8', keyBytes, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const unsigned = `${jsonPart({ alg: 'RS256', typ: 'JWT' })}.${jsonPart({
    iss: account.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: account.token_uri ?? 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  })}`;
  const signature = new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, encoder.encode(unsigned)));
  const assertion = `${unsigned}.${base64url(signature)}`;
  const response = await fetch(account.token_uri ?? 'https://oauth2.googleapis.com/token', {
    method: 'POST', headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
  });
  const body = await response.json();
  if (!response.ok) throw new Error(`Google OAuth failed: ${JSON.stringify(body)}`);
  return body.access_token as string;
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  const hookSecret = Deno.env.get('NOTIFICATION_HOOK_SECRET');
  if (!hookSecret || request.headers.get('x-hook-secret') !== hookSecret) {
    return new Response('Unauthorized', { status: 401 });
  }

  try {
    const event = await request.json();
    const url = Deno.env.get('SUPABASE_URL')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const firebase = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')!);
    const db = createClient(url, serviceKey);
    let recipientIds: string[] = [];
    let title = '';
    let body = '';
    let data: Record<string, string> = {};

    if (event.table === 'loads' && event.operation === 'INSERT') {
      const { data: drivers, error } = await db.from('profiles').select('id').eq('user_type', 'Driver').eq('is_active', true);
      if (error) throw error;
      recipientIds = (drivers ?? []).map((row) => row.id);
      title = 'New load available';
      body = `${event.record.product} · ${event.record.pickup_location} to ${event.record.delivery_location}`;
      data = { type: 'new_load', load_id: String(event.record.id) };
    } else if (event.table === 'loads' && event.operation === 'UPDATE') {
      recipientIds = [event.record.trader_id];
      title = event.record.status === 'Accepted' ? 'Your load was accepted' : 'Your load was delivered';
      body = `${event.record.product} · ${event.record.status === 'Accepted' ? 'A driver accepted your load.' : 'Your load has been delivered.'}`;
      data = { type: event.record.status === 'Accepted' ? 'load_accepted' : 'load_delivered', load_id: String(event.record.id) };
    } else if (event.table === 'support_messages' && event.operation === 'INSERT') {
      const { data: conversation, error } = await db.from('support_conversations').select('user_id').eq('id', event.record.conversation_id).single();
      if (error) throw error;
      if (conversation.user_id === event.record.sender_id) {
        const { data: admins, error: adminError } = await db.auth.admin.listUsers({ page: 1, perPage: 1000 });
        if (adminError) throw adminError;
        recipientIds = admins.users.filter((user) => user.app_metadata?.is_admin === true).map((user) => user.id);
        title = 'New support message';
        body = String(event.record.body).slice(0, 160);
        data = { type: 'support_message', conversation_id: event.record.conversation_id };
      }
    }

    if (!recipientIds.length) return Response.json({ sent: 0 });
    const { data: tokens, error: tokenError } = await db.from('device_tokens').select('token').in('user_id', recipientIds);
    if (tokenError) throw tokenError;
    if (!tokens?.length) return Response.json({ sent: 0 });

    const accessToken = await firebaseAccessToken(firebase);
    const results = await Promise.all(tokens.map(async ({ token }) => {
      const response = await fetch(`https://fcm.googleapis.com/v1/projects/${firebase.project_id}/messages:send`, {
        method: 'POST',
        headers: { authorization: `Bearer ${accessToken}`, 'content-type': 'application/json' },
        body: JSON.stringify({ message: { token, notification: { title, body }, data, android: { priority: 'HIGH' } } }),
      });
      if (!response.ok) console.error('FCM send failed', await response.text());
      return response.ok;
    }));
    return Response.json({ sent: results.filter(Boolean).length, attempted: results.length });
  } catch (error) {
    console.error(error);
    return Response.json({ error: String(error) }, { status: 500 });
  }
});
