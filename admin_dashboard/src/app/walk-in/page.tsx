'use client'
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabaseClient';
import Sidebar from '@/components/Sidebar';
import Receipt from '@/components/Receipt';
import LiveMap from '@/components/LiveMap';
import '@/app/dashboard.css';

export default function WalkInBookingPage() {
  const router = useRouter();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(false);
  const [selectedSpotId, setSelectedSpotId] = useState('');
  const [selectedSpotLabel, setSelectedSpotLabel] = useState('');
  const [selectedLocationId, setSelectedLocationId] = useState('');
  const [duration, setDuration] = useState(1);
  const [plateNumber, setPlateNumber] = useState('');
  const [createdBooking, setCreatedBooking] = useState<any>(null);

  const PRICE_PER_HOUR = 20;

  useEffect(() => {
    const auth = localStorage.getItem('admin_auth');
    if (auth === 'true') {
      setIsAuthenticated(true);
    } else {
      router.push('/login');
    }
  }, [router]);

  const handleSpotSelect = (id: string, label: string, locationId: string) => {
    setSelectedSpotId(id);
    setSelectedSpotLabel(label);
    setSelectedLocationId(locationId);
  };

  const generateBookingCode = () => {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = 'PRK-';
    for (let i = 0; i < 6; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
  };

  const handleBooking = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedSpotId) return alert('Please select a parking spot from the map.');

    setLoading(true);
    const bookingCode = generateBookingCode();
    const arrivalTime = new Date().toISOString();
    const expiresAt = new Date(Date.now() + duration * 60 * 60 * 1000).toISOString();
    const totalAmount = duration * PRICE_PER_HOUR;

    try {
      // 1. Create the booking record
      const { data: bookingData, error: bookingError } = await supabase
        .from('bookings')
        .insert([{
          booking_code: bookingCode,
          spot_id: selectedSpotId,
          location_id: selectedLocationId,
          status: 'active',
          arrival_time: arrivalTime,
          duration_hours: duration,
          total_price: totalAmount,
          payment_method: 'Cash (Walk-in)',
          booking_type: 'walk-in',
          created_at: new Date().toISOString(),
          checked_in: true,
          checked_in_at: new Date().toISOString(),
        }])
        .select('*, parking_spots(floor)')
        .single();

      if (bookingError) throw bookingError;

      // 2. Update the parking spot status
      const { error: spotError } = await supabase
        .from('parking_spots')
        .update({ status: 'occupied' })
        .eq('id', selectedSpotId);

      if (spotError) console.error('Error updating spot status:', spotError);
      
      setCreatedBooking({
        ...bookingData,
        spot_label: selectedSpotLabel,
        floor: bookingData.parking_spots?.floor || '?',
        expires_at: expiresAt
      });
      
      alert('Walk-in booking created successfully!');
    } catch (error: any) {
      console.error('Booking failed:', error);
      alert(`Booking failed: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handlePrint = () => {
    window.print();
  };

  if (!isAuthenticated) return null;

  return (
    <div className="layout">
      <Sidebar />
      <main className="main-content">
        <header className="header glass">
          <div className="header-wrapper">
             <img src="/usls_logo.png" alt="USLS Logo" className="usls-header-logo" />
             <div className="header-titles">
                <h1>Walk-in Booking</h1>
                <p className="subtitle">University of St. La Salle • Real-time Map Selection</p>
             </div>
          </div>
          <div className="admin-profile">
            <span className="glass-badge">● Live Map Mode</span>
            <div className="avatar">AD</div>
          </div>
        </header>

        <div className="walk-in-content fade-in-up" style={{ padding: '24px' }}>
          {!createdBooking ? (
            <div className="walk-in-grid" style={{ 
              display: 'grid', 
              gridTemplateColumns: '1fr 350px', 
              gap: '24px',
              alignItems: 'start'
            }}>
              {/* Map Column */}
              <section className="map-column glass" style={{ padding: '24px' }}>
                <div style={{ marginBottom: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <h2 style={{ fontSize: '1.2rem', color: 'var(--primary-deep)' }}>Select an Available Spot</h2>
                  <div className="legend" style={{ fontSize: '0.8rem' }}>
                    <span className="legend-item"><span className="dot dot-free"></span> Free</span>
                    <span className="legend-item"><span className="dot dot-occupied"></span> Occupied</span>
                  </div>
                </div>
                <LiveMap selectedSpotId={selectedSpotId} onSpotSelect={handleSpotSelect} />
              </section>

              {/* Form Column */}
              <section className="form-column glass" style={{ padding: '24px', position: 'sticky', top: '24px' }}>
                <h3 style={{ marginBottom: '1.5rem', fontSize: '1.1rem' }}>Booking Details</h3>
                <form onSubmit={handleBooking} className="walk-in-form">
                  <div className="form-group" style={{ marginBottom: '1.2rem' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: '800', opacity: 0.6, textTransform: 'uppercase' }}>Selected Spot</label>
                    <div style={{ 
                      padding: '12px', 
                      background: selectedSpotLabel ? 'var(--primary-glow)' : 'rgba(0,0,0,0.05)',
                      borderRadius: '8px',
                      fontWeight: '700',
                      color: selectedSpotLabel ? 'var(--primary-deep)' : 'var(--text-muted)',
                      border: selectedSpotLabel ? '1px solid var(--primary)' : '1px dashed rgba(0,0,0,0.2)',
                      textAlign: 'center',
                      fontSize: '1.2rem'
                    }}>
                      {selectedSpotLabel || 'Tap spot on map'}
                    </div>
                  </div>

                  <div className="form-group" style={{ marginBottom: '1.2rem' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: '800', opacity: 0.6, textTransform: 'uppercase' }}>Duration (Hours)</label>
                    <input 
                      type="number" 
                      min="1" 
                      max="24" 
                      value={isNaN(duration) ? '' : duration} 
                      onChange={(e) => {
                        const val = parseInt(e.target.value);
                        setDuration(isNaN(val) ? 0 : val);
                      }}
                      required
                      style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid rgba(0,0,0,0.1)', background: '#fff' }}
                    />
                  </div>

                  <div className="form-group" style={{ marginBottom: '1.2rem' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: '800', opacity: 0.6, textTransform: 'uppercase' }}>Vehicle Plate (Optional)</label>
                    <input 
                      type="text" 
                      placeholder="ABC 1234"
                      value={plateNumber} 
                      onChange={(e) => setPlateNumber(e.target.value)}
                      style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid rgba(0,0,0,0.1)', background: '#fff' }}
                    />
                  </div>

                  <div className="price-summary" style={{ padding: '16px', background: 'rgba(52, 199, 89, 0.05)', borderRadius: '12px', marginBottom: '1.5rem', border: '1px solid rgba(52, 199, 89, 0.1)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px', fontSize: '0.9rem' }}>
                      <span>Rate:</span>
                      <span>₱{PRICE_PER_HOUR}/hr</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: '800', fontSize: '1.1rem', color: 'var(--primary-deep)' }}>
                      <span>Total:</span>
                      <span>₱{duration * PRICE_PER_HOUR}</span>
                    </div>
                  </div>

                  <button 
                    type="submit" 
                    className="btn btn-primary" 
                    disabled={loading || !selectedSpotId}
                    style={{ width: '100%', padding: '14px', borderRadius: '12px', fontSize: '1rem' }}
                  >
                    {loading ? 'Creating...' : 'Confirm Walk-in'}
                  </button>
                </form>
              </section>
            </div>
          ) : (
            <section className="glass p-6 text-center" style={{ padding: '3rem', textAlign: 'center', maxWidth: '500px', margin: '0 auto' }}>
              <div className="success-icon" style={{ fontSize: '4rem', color: '#16a34a', marginBottom: '1rem' }}>✅</div>
              <h2 style={{ marginBottom: '0.5rem' }}>Receipt Ready!</h2>
              <p style={{ color: 'var(--text-muted)', marginBottom: '1.5rem' }}>Manual booking for {selectedSpotLabel} is now active.</p>
              
              <div className="qr-preview glass" style={{ 
                background: '#fff', 
                padding: '16px', 
                borderRadius: '16px', 
                display: 'inline-block', 
                marginBottom: '2rem',
                boxShadow: '0 4px 12px rgba(0,0,0,0.05)'
              }}>
                <img 
                  src={`https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${createdBooking.booking_code}`} 
                  alt="QR Preview" 
                  style={{ width: '120px', height: '120px' }}
                />
                <div style={{ marginTop: '8px', fontWeight: '800', color: 'var(--primary-deep)', letterSpacing: '2px' }}>
                  {createdBooking.booking_code}
                </div>
              </div>
              
              <div className="actions" style={{ display: 'flex', gap: '1rem' }}>
                <button 
                  onClick={handlePrint} 
                  className="btn btn-primary" 
                  style={{ flex: 2, padding: '14px', borderRadius: '12px' }}
                >
                  🖨️ Print Receipt
                </button>
                <button 
                  onClick={() => { setCreatedBooking(null); setSelectedSpotId(''); setSelectedSpotLabel(''); setSelectedLocationId(''); setPlateNumber(''); }} 
                  className="btn btn-outline" 
                  style={{ flex: 1, padding: '14px', borderRadius: '12px' }}
                >
                  Done
                </button>
              </div>
            </section>
          )}
        </div>

        {/* Hidden receipt for printing */}
        {createdBooking && <Receipt booking={createdBooking} />}
      </main>
    </div>
  );
}
