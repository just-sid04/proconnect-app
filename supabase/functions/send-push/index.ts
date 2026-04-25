import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"

const supabaseUrl = D some_env_var
const supabaseServiceKey = D some_env_var

serve(async (req) => {
  try {
    const payload = await req.json()
    const { record } = payload

    if (!record || !record.user_id) {
      return new Response("Invalid payload", { status: 400 })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Get User's FCM Token
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', record.user_id)
      .single()

    if (profileError || !profile?.fcm_token) {
      console.log(`No FCM token found for user ${record.user_id}`)
      return new Response("No token found", { status: 200 })
    }

    // 2. Prepare FCM Message
    const message = {
      message: {
        token: profile.fcm_token,
        notification: {
          title: record.title,
          body: record.body,
        },
        data: {
          type: record.type,
          id: record.data?.id || "",
        },
      },
    }

    // 3. Send to Firebase (Requires Service Account Auth)
    // NOTE: This assumes you have configured FIREBASE_PROJECT_ID and 
    // FIREBASE_ACCESS_TOKEN (or handled OAuth2 exchange in the function)
    
    // For this implementation, we assume a helper function or environment secret 
    // provides the capability.
    
    console.log(`Sending notification to ${record.user_id}: ${record.title}`)
    
    // MOCK SEND (Real implementation requires OAuth2 with Service Account)
    // const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    //   method: 'POST',
    //   headers: {
    //     'Authorization': `Bearer ${accessToken}`,
    //     'Content-Type': 'application/json',
    //   },
    //   body: JSON.stringify(message),
    // })

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
})
