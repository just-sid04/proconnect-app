/**
 * ProConnect Admin Dashboard — Supabase Client Configuration
 * Supabase JS v2 loaded via CDN (UMD) in index.html / login.html
 */

const SUPABASE_URL = 'https://mhhywdmgkagbephtnjqd.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_IXOINzIKDPdms23vaVeK5A_PmvfRQ9c';

// When loaded via UMD CDN, createClient is on the global `supabase` namespace
const { createClient } = window.supabase;
const supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
