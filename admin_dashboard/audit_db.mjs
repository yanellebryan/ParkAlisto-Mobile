import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://hlutfwclaoeqmoifneij.supabase.co';
const supabaseKey = 'sb_publishable_QFE7BMgyVw2wpylRDWI-FA_Xh02joel';

const supabase = createClient(supabaseUrl, supabaseKey);

async function audit() {
  console.log('--- START AUDIT ---');
  const locId = '367f5042-16cf-400b-b70a-1f39dccb735e';
  
  const { data, error } = await supabase
    .from('parking_spots')
    .select('*')
    .eq('location_id', locId)
    .order('floor', { ascending: true })
    .order('row_letter', { ascending: true })
    .order('spot_number', { ascending: true });

  if (error) {
    console.error('Error:', error);
    return;
  }

  console.log('Total spots for USLS ID:', data.length);
  
  if (data.length === 0) {
    console.log('No spots found for USLS ID. Trying to find by name...');
    const { data: locs } = await supabase.from('parking_locations').select('id, name').ilike('name', '%Salle%');
    console.log('Locations found:', locs);
    if (locs && locs.length > 0) {
        // Retry with the first one found
        const firstId = locs[0].id;
        console.log(`Retrying with ID: ${firstId}`);
        const { data: retryData } = await supabase.from('parking_spots').select('*').eq('location_id', firstId).order('floor', { ascending: true }).order('row_letter', { ascending: true }).order('spot_number', { ascending: true });
        if (retryData) {
            data.push(...retryData);
        }
    }
  }

  for (let f = 1; f <= 3; f++) {
    const floorSpots = data.filter(s => s.floor === f);
    console.log(`\nFloor ${f} (Count: ${floorSpots.length}):`);
    floorSpots.slice(0, 5).forEach(s => {
      console.log(`- ${s.label} (row: ${s.row_letter}, num: ${s.spot_number})`);
    });
  }
}

audit();
