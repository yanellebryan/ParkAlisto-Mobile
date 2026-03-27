'use client'
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabaseClient';
import './components.css';

export default function BookingsTable() {
  const [bookings, setBookings] = useState<any[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [copyingId, setCopyingId] = useState<string | null>(null);

  useEffect(() => {
    // 1. Fetch initial bookings with joined data
    const fetchBookings = async () => {
      // 1. Get ALL locations that might be USLS
      const { data: locations, error: locError } = await supabase
        .from('parking_locations')
        .select('id, name')
        .or('name.ilike.%La Salle%,name.ilike.%USLS%');

      if (locError) {
        console.error('Error fetching locations for bookings:', locError);
        return;
      }

      if (locations && locations.length > 0) {
        let locWithSpots = null;

        // 2. Try to find which one has spots (to identify the "active" record)
        for (const loc of locations) {
          const { count } = await supabase
            .from('parking_spots')
            .select('*', { count: 'exact', head: true })
            .eq('location_id', loc.id);
          
          if (count && count > 0) {
            locWithSpots = loc;
            break;
          }
        }

        const { data } = await supabase
          .from('bookings')
          .select('*, parking_spots(row_letter, spot_number, floor)')
          .order('created_at', { ascending: false })
          .limit(20);

        if (data) setBookings(data);
      }
    };

    fetchBookings();

    // 2. Subscribe to real-time changes
    const channel = supabase
      .channel('usls_bookings_monitoring')
      .on('postgres_changes', { 
        event: '*', 
        schema: 'public', 
        table: 'bookings' 
      }, (payload) => {
        fetchBookings(); // Always refetch to get the latest joined data
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const handleConfirm = async (bookingId: string) => {
    try {
      const { error } = await supabase
        .from('bookings')
        .update({ status: 'confirmed' })
        .eq('id', bookingId);
      
      if (error) throw error;
      // Real-time will trigger refetch
    } catch (err) {
      console.error('Error confirming booking:', err);
    }
  }

  const handleCancel = async (bookingId: string, spotId: string) => {
     if (!confirm('Are you sure you want to cancel this booking/free the spot?')) return;
     await supabase.from('bookings').update({ status: 'cancelled' }).eq('id', bookingId);
     await supabase.from('parking_spots').update({ status: 'available' }).eq('id', spotId);
  }

  const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopyingId(id);
    setTimeout(() => setCopyingId(null), 2000);
  };

  // Filtered and searched results
  const filteredBookings = bookings.filter(b => {
    const matchesSearch = 
      b.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (b.full_name && b.full_name.toLowerCase().includes(searchTerm.toLowerCase()));
    
    const matchesStatus = filterStatus === 'all' || b.status === filterStatus;
    
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="bookings-container fade-in-up delay-2">
      <div className="table-wrapper">
        <div className="table-header-row">
          <div className="header-left">
            <h3>Reservations List</h3>
            <p className="subtitle">Real-time USLS parking monitoring</p>
          </div>
          <div className="header-right">
             <div className="search-box">
                <span className="search-icon">🔍</span>
                <input 
                  type="text" 
                  placeholder="Search by ID or name..." 
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
             </div>
          </div>
        </div>

        {/* Filter Tabs */}
        <div className="filter-tabs-container">
          <div className="filter-tabs">
            {['all', 'active', 'confirmed', 'cancelled'].map(status => (
              <button 
                key={status}
                className={`filter-tab ${filterStatus === status ? 'active' : ''}`}
                onClick={() => setFilterStatus(status)}
              >
                {status.charAt(0) + status.slice(1)}
              </button>
            ))}
          </div>
        </div>

        <div className="table-scroll-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Status</th>
                <th>Booking Code</th>
                <th>Parking Spot</th>
                <th>Floor</th>
                <th>Booked At</th>
                <th>Arrival Time</th>
                <th>Duration</th>
                <th style={{textAlign: 'right'}}>Amount</th>
                <th style={{textAlign: 'right'}}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredBookings.map(b => (
                 <tr key={b.id} className={`booking-row ${b.status === 'active' || b.status === 'confirmed' ? 'row-active' : ''}`}>
                  <td>
                    <span className={`status-pill ${b.status}`}>
                      {b.status === 'active' && <span className="mini-pulse"></span>}
                      {b.status.toUpperCase()}
                    </span>
                  </td>
                  <td className="code-cell">
                    <div className="code-container" title={b.id}>
                      <span className="code-text">...{b.id.slice(-8)}</span>
                      <button 
                        className={`copy-btn ${copyingId === b.id ? 'copied' : ''}`}
                        onClick={() => copyToClipboard(b.id, b.id)}
                        title="Copy full UUID"
                      >
                        {copyingId === b.id ? '✓' : '📋'}
                      </button>
                    </div>
                  </td>
                  <td className="spot-cell">
                    <div className="spot-badge">
                      <span className="spot-letter">{b.parking_spots?.row_letter || '?' }</span>
                      <span className="spot-num">{b.parking_spots?.spot_number || '-' }</span>
                    </div>
                  </td>
                  <td>
                    <span className="floor-badge">FL {b.parking_spots?.floor || '1'}</span>
                  </td>
                  <td className="time-display">
                    <div className="main-time">{new Date(b.created_at).toLocaleTimeString('en-PH', {hour: '2-digit', minute:'2-digit', timeZone: 'Asia/Manila'})}</div>
                    <div className="sub-date">{new Date(b.created_at).toLocaleDateString('en-PH', { month: 'short', day: 'numeric', year: 'numeric', timeZone: 'Asia/Manila' })}</div>
                  </td>
                  <td className="arrival-time-display">
                    <div className="arrival-time" style={{fontWeight: b.arrival_time ? '700' : '400', color: b.arrival_time ? 'var(--primary-deep)' : 'rgba(0,0,0,0.4)'}}>
                      {b.arrival_time ? new Date(b.arrival_time).toLocaleTimeString('en-PH', {hour: '2-digit', minute:'2-digit', timeZone: 'Asia/Manila'}) : 'Not set'}
                    </div>
                    <div className="sub-date" style={{fontSize: '0.75rem', opacity: 0.6}}>
                       {b.arrival_time ? new Date(b.arrival_time).toLocaleDateString('en-PH', { month: 'short', day: 'numeric', timeZone: 'Asia/Manila' }) : ''}
                    </div>
                  </td>
                  <td className="duration-display">
                    <span className="duration-tag">{b.duration_hours}h</span>
                  </td>
                  <td className="amount-cell">
                     <div className="amount-value">₱{b.total_price || 0}</div>
                     <div className="payment-method-label">{b.payment_method || 'Cash'}</div>
                  </td>
                  <td style={{textAlign: 'right'}}>
                    <div className="labeled-actions">
                      {b.status === 'active' && (
                        <button 
                          className="btn-action-labeled btn-confirm-labeled"
                          onClick={() => handleConfirm(b.id)}
                        >
                          <span className="btn-icon">✓</span>
                          <span>Confirm</span>
                        </button>
                      )}
                      <button 
                        className="btn-action-labeled btn-cancel-labeled"
                        onClick={() => handleCancel(b.id, b.spot_id)}
                        disabled={b.status === 'cancelled' || b.status === 'confirmed'}
                      >
                        <span className="btn-icon">✕</span>
                        <span>Cancel</span>
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {filteredBookings.length === 0 && (
                <tr>
                  <td colSpan={8} className="empty-state">
                    <div className="empty-icon">🔍</div>
                    <p>No reservations matching your criteria.</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
