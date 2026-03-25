import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://hlutfwclaoeqmoifneij.supabase.co'
const supabaseKey = 'sb_publishable_QFE7BMgyVw2wpylRDWI-FA_Xh02joel'

// Initialize the Supabase client footprint for Next.js mapping to the Flutter db
export const supabase = createClient(supabaseUrl, supabaseKey)
