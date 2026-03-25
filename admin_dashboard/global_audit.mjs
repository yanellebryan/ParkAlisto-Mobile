import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://hlutfwclaoeqmoifneij.supabase.co';
const supabaseKey = 'sb_publishable_QFE7BMgyVw2wpylRDWI-FA_Xh02joel';

const supabase = createClient(supabaseUrl, supabaseKey);

async function audit() {
  console.log('--- GLOBAL AUDIT ---');
  
  const { data: locs } = await supabase.from('parking_locations').select('id, name').ilike('name', '%Salle%');
  console.log('USLS-related locations found:', locs);
  
  for (const loc of locs) {
    const { data: spots } = await supabase
      .from('parking_spots')
      .select('*')
      .eq('location_id', loc.id)
      .order('floor', { ascending: true })
      .order('row_letter', { ascending: true })
      .order('spot_number', { ascending: true });
      
    console.log(`\nLocation: ${loc.name} (${loc.id})`);
    console.log(`Total spots: ${spots.length}`);
    if (spots.length > 0) {
      console.log('First Floor (First 5):');
      spots.filter(s => s.floor === 1 || !s.floor).slice(0, 5).forEach(s => {
        console.log(`- ${s.label} (row: ${s.row_letter}, num: ${s.spot_number}, floor: ${s.floor})`);
      });
    }
  }
}

audit();
