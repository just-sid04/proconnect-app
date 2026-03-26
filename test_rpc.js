const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://mhhywdmgkagbephtnjqd.supabase.co';
const supabaseKey = 'sb_publishable_IXOINzIKDPdms23vaVeK5A_PmvfRQ9c';
const supabase = createClient(supabaseUrl, supabaseKey);

async function testRpc() {
  console.log('Testing get_user_recommendations RPC...');
  
  // We'll try with a dummy UUID first to see if the function exists
  const { data, error } = await supabase.rpc('get_user_recommendations', {
    p_user_id: '00000000-0000-0000-0000-000000000000'
  });

  if (error) {
    console.error('RPC Error:', error);
    if (error.code === 'P0001') {
      console.log('Function exists but returned an error or empty.');
    } else if (error.message.includes('not found')) {
      console.log('CRITICAL: Function get_user_recommendations does NOT exist in the database.');
    }
  } else {
    console.log('RPC Success! Data received:', data);
    if (data && data.length > 0) {
      console.log(`Received ${data.length} recommendations.`);
    } else {
      console.log('Received 0 recommendations. Fallback logic might be failing or no active categories.');
    }
  }
}

testRpc();
