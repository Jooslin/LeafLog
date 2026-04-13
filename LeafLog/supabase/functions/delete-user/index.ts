import { createClient } from 'npm:@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

if (!supabaseUrl || !anonKey || !serviceRoleKey) {
  throw new Error('Missing Supabase environment variables.')
}

const adminClient = createClient(supabaseUrl, serviceRoleKey)

Deno.serve(async (req) => {
  const authHeader = req.headers.get('Authorization')

  if (!authHeader) {
    return new Response(JSON.stringify({ message: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: {
      headers: {
        Authorization: authHeader,
      },
    },
  })

  const { data, error } = await userClient.auth.getUser()

  if (error || !data.user) {
    return new Response(JSON.stringify({ message: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const user = data.user

  const { error: profileDeleteError } = await adminClient
    .from('profiles')
    .delete()
    .eq('id', user.id)

  if (profileDeleteError) {
    return new Response(JSON.stringify({ message: profileDeleteError.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const { error: deleteUserError } = await adminClient.auth.admin.deleteUser(user.id)

  if (deleteUserError) {
    return new Response(JSON.stringify({ message: deleteUserError.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  })
})
