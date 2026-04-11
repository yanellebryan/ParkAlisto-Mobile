'use client'
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabaseClient';
import './components.css';

export default function LiveMap({ 
  selectedSpotId, 
  onSpotSelect 
}: { 
  selectedSpotId?: string, 
  onSpotSelect?: (id: string, label: string) => void 
}) {
  const [spots, setSpots] = useState<any[]>([]);
  const [floor, setFloor] = useState(0); // 0, 1, 2 for Floor 1, 2, 3
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchUSLSSpots = async () => {
      setLoading(true);
      setError(null);
      try {
        // 1. Get ALL locations that might be USLS
        const { data: locations, error: locError } = await supabase
          .from('parking_locations')
          .select('id, name')
          .or('name.ilike.%La Salle%,name.ilike.%USLS%');
        
        if (locError) throw locError;
        
        if (locations && locations.length > 0) {
          let foundSpots = false;

          // 2. Try to find spots for ANY of these locations
          for (const loc of locations) {
            const { data: spotData, error: spotError } = await supabase
              .from('parking_spots')
              .select('*')
              .eq('location_id', loc.id)
              .order('floor', { ascending: true })
              .order('row_letter', { ascending: true })
              .order('spot_number', { ascending: true });
            
            if (spotError) throw spotError;

            if (spotData && spotData.length > 0) {
              setSpots(spotData);
              foundSpots = true;
              console.log(`Successfully loaded ${spotData.length} spots for: ${loc.name}`);
              break; // Found the right one!
            }
          }

          if (!foundSpots) {
            setError(`Found ${locations.length} USLS-related locations, but none of them have spots registered in the 'parking_spots' table.`);
          }
        } else {
          setError("USLS location record not found in 'parking_locations' table.");
        }
      } catch (err: any) {
        console.error("Error fetching USLS data:", err);
        setError(err.message || "An unexpected error occurred");
      } finally {
        setLoading(false);
      }
    };

    fetchUSLSSpots();

    // Subscribe to real-time changes
    console.log("Supabase Realtime: Subscribing to parking_spots changes...");
    const channel = supabase
      .channel('usls_spots_monitoring') // Unique channel name
      .on('postgres_changes', { 
        event: '*', 
        schema: 'public', 
        table: 'parking_spots' 
      }, (payload: any) => {
        console.log("Supabase Realtime: Received event!", payload);
        if (payload.eventType === 'UPDATE') {
          setSpots(currentSpots => 
            currentSpots.map(s => s.id === payload.new.id ? { ...s, ...payload.new } : s)
          );
        } else if (payload.eventType === 'INSERT') {
          // Check if this new spot belongs to our USLS location
          fetchUSLSSpots();
        } else if (payload.eventType === 'DELETE') {
          setSpots(currentSpots => currentSpots.filter(s => s.id !== payload.old.id));
        }
      })
      .subscribe((status) => {
        console.log("Supabase Realtime: Subscription status:", status);
      });

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  if (loading) {
    return <div style={{ color: "var(--text-muted)" }}>Connecting to live map...</div>;
  }

  if (error) {
    return (
      <div style={{ 
        padding: '24px', 
        borderRadius: '16px', 
        background: 'rgba(255, 59, 48, 0.05)', 
        border: '1px solid rgba(255, 59, 48, 0.2)',
        color: 'var(--danger)',
        fontSize: '0.9rem',
        textAlign: 'center'
      }}>
        <p style={{ fontWeight: 700, marginBottom: '8px' }}>⚠️ Data Loading Error</p>
        <p>{error}</p>
        <button 
          onClick={() => window.location.reload()}
          style={{
            marginTop: '16px',
            padding: '8px 16px',
            borderRadius: '8px',
            border: 'none',
            background: 'var(--danger)',
            color: 'white',
            fontWeight: 600,
            cursor: 'pointer'
          }}
        >
          Retry Connection
        </button>
      </div>
    );
  }

  if (spots.length === 0) {
    return <div style={{ color: "var(--text-muted)" }}>No parking spots available.</div>;
  }

  // Helper to render a spot
  const renderSpot = (spot: any) => {
    if (!spot) return <div className="usls-spot" style={{ visibility: 'hidden' }}></div>;
    const isSelected = selectedSpotId === spot.id;
    const isOccupied = spot.status === 'occupied';

    return (
      <div 
        key={spot.id} 
        className={`spot-card usls-spot ${isOccupied ? 'spot-occupied' : 'spot-free'} ${isSelected ? 'spot-selected' : ''}`}
        title={`Row ${spot.row_letter} - Spot ${spot.spot_number}`}
        onClick={() => {
          if (!isOccupied && onSpotSelect) {
            onSpotSelect(spot.id, spot.label || `${spot.row_letter}${spot.spot_number}`);
          }
        }}
        style={{ cursor: isOccupied ? 'not-allowed' : 'pointer' }}
      >
        <span className="spot-name">{spot.label || `${spot.row_letter}${spot.spot_number}`}</span>
        {isSelected && <div className="selection-indicator">✓</div>}
      </div>
    );
  };

  // USLS Layout Logic (matching mobile app label-based mapping)
  // Filter spots for the current floor using the explicit 'floor' field
  const currentFloorSpots = spots.filter((s: any) => s.floor === floor + 1);

  // Helper to get spot by row and number
  const getSpot = (row: string, num: number) => {
    const label = `${row}${num}`;
    return currentFloorSpots.find(s => (s.label === label) || (s.row_letter === row && s.spot_number === num));
  };

  // Determine which rows are on this floor
  const floorRows = [
    ['A', 'B', 'C', 'D'],
    ['E', 'F', 'G', 'H'],
    ['I', 'J', 'K', 'L']
  ][floor];

  const [r1, r2, r3, r4] = floorRows;

  // Top Row: Row 1, Spots 1-3
  const topRow = [getSpot(r1, 1), getSpot(r1, 2), getSpot(r1, 3)];

  // Section A (Left): 2 columns
  // Row 1 (4-6), Row 2 (1-6), Row 3 (1-5) -> 14 spots
  const sectionASpots = [
    getSpot(r1, 4), getSpot(r1, 5),
    getSpot(r1, 6), getSpot(r2, 1),
    getSpot(r2, 2), getSpot(r2, 3),
    getSpot(r2, 4), getSpot(r2, 5),
    getSpot(r2, 6), getSpot(r3, 1),
    getSpot(r3, 2), getSpot(r3, 3),
    getSpot(r3, 4), getSpot(r3, 5),
  ];

  // Section B (Right): 1 column
  // Row 3 (6), Row 4 (1-6) -> 7 spots
  const sectionB = [
    getSpot(r3, 6),
    getSpot(r4, 1),
    getSpot(r4, 2),
    getSpot(r4, 3),
    getSpot(r4, 4),
    getSpot(r4, 5),
    getSpot(r4, 6),
  ];

  const sectionA = [];
  for (let i = 0; i < 7; i++) {
    sectionA.push([sectionASpots[i * 2], sectionASpots[i * 2 + 1]]);
  }

  return (
    <div>
      <div className="floor-selector">
        {[0, 1, 2].map((f) => (
          <div 
            key={f} 
            className={`floor-tab ${floor === f ? 'active' : ''}`}
            onClick={() => setFloor(f)}
          >
            Floor {f + 1}
          </div>
        ))}
      </div>

      <div className="usls-layout-container">
        <div className="layout-badge badge-entrance">
          <span>↑ Entrance</span>
        </div>

        <div className="usls-top-row">
          {topRow.map((spot, idx) => <div key={`top-${idx}`}>{renderSpot(spot)}</div>)}
        </div>

        <div className="driveway-divider">
          ↔ DRIVEWAY ↔
        </div>

        <div className="usls-body">
          <div className="section-a">
            <div className="section-label">SECTION A</div>
            {sectionA.map((row, idx) => (
              <div key={`row-a-${idx}`} className="section-a-row">
                {renderSpot(row[0])}
                {renderSpot(row[1])}
              </div>
            ))}
          </div>

          <div className="section-b">
            <div className="section-label">SECTION B</div>
            {sectionB.map((spot, idx) => (
              <div key={`row-b-${idx}`}>
                {renderSpot(spot)}
              </div>
            ))}
          </div>
        </div>


        <div className="layout-badge badge-exit" style={{ marginTop: '16px' }}>
          <span>↓ Exit</span>
        </div>
      </div>
    </div>
  );
}
