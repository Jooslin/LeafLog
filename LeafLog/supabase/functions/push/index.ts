import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'
import serviceAccount from '../service-account.json' with { type: 'json' }

interface Notification {
  id: string
  user_id: string
  body: string
}

interface WebhookPayload {
  type: 'INSERT'
  table: string
  record: Notification
  schema: 'public'
}

const supabaseUrl = Deno.env.get('SUPABASE_URL');
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables.');
  throw new Error('Configuration error: Missing Supabase environment variables');
}

const supabase = createClient(supabaseUrl, supabaseKey);

Deno.serve(async (req) => {
  const payload: WebhookPayload = await req.json()

  const { data } = await supabase
    .from('profiles')
    .select('fcm_token, is_notification_enabled')
    .eq('id', payload.record.user_id)
    .single()

  // 알림이 비활성화되어 있거나 토큰이 없는 경우 스킵
  if (!data?.is_notification_enabled || !data?.fcm_token) {
    const reason = !data?.is_notification_enabled ? 'User disabled notifications' : 'Missing FCM token';
    return new Response(JSON.stringify({ message: `Notification skipped: ${reason}` }), {
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const fcmToken = data.fcm_token as string

  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {
            title: `Notification from Supabase`,
            body: payload.record.body,
          },
        },
      }),
    }
  )

  const resData = await res.json()
  if (res.status < 200 || 299 < res.status) {
    throw resData
  }

  return new Response(JSON.stringify(resData), {
    headers: { 'Content-Type': 'application/json' },
  })
})

const getAccessToken = ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string
  privateKey: string
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err);
        return;
      }
      if (!tokens || !tokens.access_token) {
        reject(new Error('Failed to retrieve access token: Token is missing or invalid.'));
        return;
      }
      resolve(tokens.access_token);
    })
  })
}