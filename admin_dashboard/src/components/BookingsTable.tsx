'use client'
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabaseClient';
import './components.css';

export default function BookingsTable() {
  const [bookings, setBookings] = useState<any[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [copyingId, setCopyingId] = useState<string | null>(null);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);


  // 1. Define fetchBookings outside useEffect so it's reusable
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
      const { data } = await supabase
        .from('bookings')
        .select('*, spot_id, parking_spots(row_letter, spot_number, floor)')
        .order('created_at', { ascending: false })
        .limit(50);

      if (data) setBookings(data);
    }
  };

  useEffect(() => {
    fetchBookings();

    // 1. WebSocket Channel (Realtime Push)
    const channel = supabase
      .channel('usls_bookings_monitoring')
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'bookings'
      }, () => {
        fetchBookings(); 
      })
      .subscribe();

    // 2. Poll fallback (Pull every 5 seconds)
    const pollInterval = setInterval(() => {
      fetchBookings();
    }, 5000);

    return () => {
      supabase.removeChannel(channel);
      clearInterval(pollInterval);
    };
  }, []);

  const handleConfirm = async (bookingId: string) => {
    try {
      setActionLoadingId(bookingId);
      
      // OPTIMISTIC UPDATE: Update local state immediately for instant disappearing effect
      setBookings(prev => prev.map(b => b.id === bookingId ? { ...b, status: 'confirmed' } : b));

      const { data, error } = await supabase
        .from('bookings')
        .update({ status: 'completed' })
        .eq('id', bookingId)
        .select();

      if (error) {
        console.error('Supabase update failure:', error);
        alert(`Failed to reflect in Supabase: ${error.message}`);
        fetchBookings(); // Rollback
        throw error;
      }
      
      if (data && data.length > 0) {
        console.log('Completed successfully in Supabase:', data[0]);
      } else {
        console.warn('Update executed but 0 rows affected. Check RLS or ID match.');
      }
      
      // Trigger a fresh fetch
      setTimeout(fetchBookings, 500); 

    } catch (err) {
      console.error('Error confirming booking:', err);
    } finally {
      setActionLoadingId(null);
    }
  }

  const handleCancel = async (bookingId: string, spotId: string) => {
    try {
      setActionLoadingId(bookingId);
      
      // OPTIMISTIC UPDATE: Update local state immediately
      setBookings(prev => prev.map(b => b.id === bookingId ? { ...b, status: 'cancelled' } : b));

      // 1. Update booking status
      const { data: bData, error: bookingError } = await supabase
        .from('bookings')
        .update({ status: 'cancelled' })
        .eq('id', bookingId)
        .select();

      if (bookingError) {
        alert(`Booking status update failed: ${bookingError.message}`);
        fetchBookings();
        throw bookingError;
      }

      // 2. Free the spot
      if (spotId) {
        const { error: spotError } = await supabase
          .from('parking_spots')
          .update({ status: 'available' })
          .eq('id', spotId);
        
        if (spotError) {
          console.error('Failed to free spot in DB:', spotError);
        } else {
          console.log(`Spot ${spotId} is now available in Supabase.`);
        }
      }

      console.log('Cancelled booking successfully:', bData ? bData[0] : 'No data back');
      
      // Trigger fresh fetch
      setTimeout(fetchBookings, 800);

    } catch (err) {
      console.error('Error cancelling booking:', err);
    } finally {
      setActionLoadingId(null);
    }
  }


  const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopyingId(id);
    setTimeout(() => setCopyingId(null), 2000);
  };

  // Filtered and searched results
  const filteredBookings = bookings.filter(b => {
    const bStatus = (b.status || '').toLowerCase();
    const bName = (b.full_name || '').toLowerCase();
    const bId = (b.id || '').toLowerCase();

    const matchesSearch =
      bId.includes(searchTerm.toLowerCase()) ||
      bName.includes(searchTerm.toLowerCase());

    const matchesStatus = filterStatus === 'all' || bStatus === filterStatus;

    return matchesSearch && matchesStatus;
  });

  // Separate into Active/History for default multi-table view
  const activeBookingsList = filteredBookings.filter(b => (b.status || '').toLowerCase() === 'active');
  const historyBookingsList = filteredBookings.filter(b =>
    (b.status || '').toLowerCase() === 'completed' ||
    (b.status || '').toLowerCase() === 'cancelled'
  );

  const renderTable = (list: any[], title: string, subtitle: string, isActiveTable: boolean) => (
    <div className="table-wrapper" style={{ marginBottom: '32px' }}>
      <div className="table-header-row">
        <div className="header-left">
          <h3>{title}</h3>
          <p className="subtitle">{subtitle}</p>
        </div>
        {isActiveTable && (
          <div className="header-right">
            <div className="search-box">
              <span className="search-icon">🔍</span>
              <input
                type="text"
                placeholder="Search reservations..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
        )}
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
              <th style={{ textAlign: 'right' }}>Amount</th>
              <th style={{ textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {list.map(b => {
              const statusLower = (b.status || '').toLowerCase();
              return (
                <tr key={b.id} className={`booking-row ${statusLower === 'active' || statusLower === 'completed' ? 'row-active' : ''}`}>
                  <td>
                    <span className={`status-pill ${statusLower}`}>
                      {statusLower === 'active' && <span className="mini-pulse"></span>}
                      {statusLower.toUpperCase()}
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
                      <span className="spot-letter">{b.parking_spots?.row_letter || '?'}</span>
                      <span className="spot-num">{b.parking_spots?.spot_number || '-'}</span>
                    </div>
                  </td>
                  <td>
                    <span className="floor-badge">FL {b.parking_spots?.floor || '1'}</span>
                  </td>
                  <td className="time-display">
                    <div className="main-time">{new Date(b.created_at).toLocaleTimeString('en-PH', { hour: '2-digit', minute: '2-digit', timeZone: 'Asia/Manila' })}</div>
                    <div className="sub-date">{new Date(b.created_at).toLocaleDateString('en-PH', { month: 'short', day: 'numeric', year: 'numeric', timeZone: 'Asia/Manila' })}</div>
                  </td>
                  <td className="arrival-time-display">
                    <div className="arrival-time" style={{ fontWeight: b.arrival_time ? '700' : '400', color: b.arrival_time ? 'var(--primary-deep)' : 'rgba(0,0,0,0.4)' }}>
                      {b.arrival_time ? new Date(b.arrival_time).toLocaleTimeString('en-PH', { hour: '2-digit', minute: '2-digit', timeZone: 'Asia/Manila' }) : 'Not set'}
                    </div>
                    <div className="sub-date" style={{ fontSize: '0.75rem', opacity: 0.6 }}>
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
                  <td style={{ textAlign: 'right' }}>
                    <div className="labeled-actions">
                      {(statusLower === 'active') && (
                        <button
                          className="btn-action-labeled btn-confirm-labeled"
                          onClick={() => handleConfirm(b.id)}
                          disabled={actionLoadingId === b.id}
                        >
                          <span className="btn-icon">{actionLoadingId === b.id ? '⏳' : '✓'}</span>
                          <span>{actionLoadingId === b.id ? 'Saving...' : 'Complete'}</span>
                        </button>
                      )}
                      <button
                        className="btn-action-labeled btn-cancel-labeled"
                        onClick={() => handleCancel(b.id, b.spot_id)}
                        disabled={statusLower === 'cancelled' || actionLoadingId === b.id}
                      >
                        <span className="btn-icon">{actionLoadingId === b.id ? '⏳' : '✕'}</span>
                        <span>{isActiveTable ? 'Cancel' : 'Release Spot'}</span>
                      </button>
                    </div>
                  </td>
                </tr>
              )
            })}

            {list.length === 0 && (
              <tr>
                <td colSpan={9} className="empty-state">
                  <div className="empty-icon">🔍</div>
                  <p>No {title.toLowerCase()} matching your criteria.</p>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );


  return (
    <div className="bookings-container fade-in-up delay-2">
      <div className="filter-tabs-container">
        <div className="filter-tabs">
          {['all', 'active', 'completed', 'cancelled'].map(status => (
            <button
              key={status}
              className={`filter-tab ${filterStatus === status ? 'active' : ''}`}
              onClick={() => setFilterStatus(status)}
            >
              {status.charAt(0).toUpperCase() + status.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {/* Primary Table: Active */}
      {(filterStatus === 'all' || filterStatus === 'active') &&
        renderTable(activeBookingsList, "Active Reservations", "Pending arrivals and check-ins", true)
      }

      {/* Secondary Table: History */}
      {(filterStatus === 'all' || filterStatus === 'confirmed' || filterStatus === 'cancelled') &&
        renderTable(historyBookingsList, "Booking History", "Processed records and historical logs", false)
      }
    </div>
  );
}
