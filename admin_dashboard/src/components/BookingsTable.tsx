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
  const [showCancelModal, setShowCancelModal] = useState<{ id: string; spotId: string } | null>(null);
  const [cancelReason, setCancelReason] = useState('');

  // ── Fetch all bookings ────────────────────────────────────
  const fetchBookings = async () => {
    const { data } = await supabase
      .from('bookings')
      .select('*, spot_id, parking_spots(row_letter, spot_number, floor)')
      .order('created_at', { ascending: false })
      .limit(50);

    if (data) setBookings(data);
  };

  useEffect(() => {
    fetchBookings();

    const channel = supabase
      .channel('usls_bookings_monitoring')
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'bookings'
      }, () => fetchBookings())
      .subscribe();

    const pollInterval = setInterval(fetchBookings, 5000);

    return () => {
      supabase.removeChannel(channel);
      clearInterval(pollInterval);
    };
  }, []);

  // ── Compute expiry time for a booking ────────────────────
  const getExpiresAt = (booking: any): Date | null => {
    const base = booking.arrival_time
      ? new Date(booking.arrival_time)
      : booking.booking_date
        ? new Date(booking.booking_date)
        : null;
    if (!base) return null;
    const extra = booking.arrival_time ? 0 : 2; // safety buffer if no arrival_time
    return new Date(base.getTime() + (booking.duration_hours + extra) * 3600 * 1000);
  };

  const formatExpiry = (booking: any): string => {
    const exp = getExpiresAt(booking);
    if (!exp) return 'Unknown';
    const isExpired = exp < new Date();
    const timeStr = exp.toLocaleTimeString('en-PH', {
      hour: '2-digit', minute: '2-digit', timeZone: 'Asia/Manila'
    });
    const dateStr = exp.toLocaleDateString('en-PH', {
      month: 'short', day: 'numeric', timeZone: 'Asia/Manila'
    });
    return `${timeStr} ${dateStr}${isExpired ? ' (Expired)' : ''}`;
  };

  const isExpired = (booking: any): boolean => {
    const exp = getExpiresAt(booking);
    return exp ? exp < new Date() : false;
  };

  // ── Confirm (complete) a booking ─────────────────────────
  const handleConfirm = async (bookingId: string) => {
    try {
      setActionLoadingId(bookingId);
      setBookings(prev => prev.map(b => b.id === bookingId ? { ...b, status: 'completed' } : b));

      const { data, error } = await supabase
        .from('bookings')
        .update({ status: 'completed' })
        .eq('id', bookingId)
        .select();

      if (error) {
        alert(`Failed: ${error.message}`);
        fetchBookings();
        throw error;
      }
      if (data && data.length > 0) {
        console.log('Completed:', data[0]);
        // Release the spot status
        const spotId = data[0].spot_id;
        if (spotId) {
          const { error: spotError } = await supabase
            .from('parking_spots')
            .update({ status: 'available' })
            .eq('id', spotId);
          if (spotError) console.error('Failed to free spot on manual confirm:', spotError);
        }
      }
      setTimeout(fetchBookings, 500);
    } catch (err) {
      console.error('Error completing booking:', err);
    } finally {
      setActionLoadingId(null);
    }
  };

  // ── Cancel a booking (with reason) ───────────────────────
  const handleCancelConfirm = async () => {
    if (!showCancelModal) return;
    const { id: bookingId, spotId } = showCancelModal;

    try {
      setActionLoadingId(bookingId);
      setBookings(prev => prev.map(b => b.id === bookingId ? { ...b, status: 'cancelled' } : b));

      const { error: bookingError } = await supabase
        .from('bookings')
        .update({
          status: 'cancelled',
          cancellation_reason: cancelReason.trim() || null,
        })
        .eq('id', bookingId);

      if (bookingError) {
        alert(`Booking update failed: ${bookingError.message}`);
        fetchBookings();
        throw bookingError;
      }

      if (spotId) {
        const { error: spotError } = await supabase
          .from('parking_spots')
          .update({ status: 'available' })
          .eq('id', spotId);
        if (spotError) console.error('Failed to free spot:', spotError);
      }

      console.log('Booking cancelled with reason:', cancelReason);
      setTimeout(fetchBookings, 800);
    } catch (err) {
      console.error('Error cancelling booking:', err);
    } finally {
      setActionLoadingId(null);
      setShowCancelModal(null);
      setCancelReason('');
    }
  };

  // ── Copy to clipboard ─────────────────────────────────────
  const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopyingId(id);
    setTimeout(() => setCopyingId(null), 2000);
  };

  // ── Filter and search ─────────────────────────────────────
  const filteredBookings = bookings.filter(b => {
    const bStatus = (b.status || '').toLowerCase();
    const bCode = (b.booking_code || '').toLowerCase();
    const bId = (b.id || '').toLowerCase();

    const matchesSearch =
      bId.includes(searchTerm.toLowerCase()) ||
      bCode.includes(searchTerm.toLowerCase());

    const matchesStatus = filterStatus === 'all' || bStatus === filterStatus;
    return matchesSearch && matchesStatus;
  });

  const activeBookingsList = filteredBookings.filter(b => (b.status || '').toLowerCase() === 'active');
  const historyBookingsList = filteredBookings.filter(b =>
    ['completed', 'cancelled'].includes((b.status || '').toLowerCase())
  );

  // ── Render table ──────────────────────────────────────────
  const renderTable = (list: any[], title: string, subtitle: string, isActiveTable: boolean) => (
    <div className="table-wrapper" style={{ marginBottom: '32px' }}>
      <div className="table-header-row">
        <div className="header-left">
          <h3>{title}</h3>
          <p className="subtitle">{subtitle}</p>
        </div>
        {isActiveTable && (
          <div className="header-right" style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
            {/* Entry QR Scan button */}
            <button
              className="btn-scan-qr"
              onClick={() => window.open('/scanner', '_blank')}
              title="Open Entry QR Scanner in a new tab"
            >
              <span>📷</span>
              <span>Entry QR</span>
            </button>
            {/* Exit QR Scan button */}
            <button
              className="btn-scan-qr"
              onClick={() => window.open('/exit-scanner', '_blank')}
              title="Open Exit QR Scanner in a new tab"
              style={{ background: 'linear-gradient(135deg, #16a34a, #22c55e)', color: '#fff' }}
            >
              <span>🚪</span>
              <span>Exit QR</span>
            </button>
            <div className="search-box">
              <span className="search-icon">🔍</span>
              <input
                type="text"
                placeholder="Search by code or ID..."
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
              {isActiveTable && <th>Expires At</th>}
              <th>Duration</th>
              <th>Source</th>
              <th style={{ textAlign: 'right' }}>Amount</th>
              <th style={{ textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {list.map(b => {
              const statusLower = (b.status || '').toLowerCase();
              const expired = isActiveTable && isExpired(b);

              return (
                <tr key={b.id} className={`booking-row ${statusLower === 'active' ? 'row-active' : ''} ${expired ? 'row-expired' : ''}`}>
                  <td>
                    <span className={`status-pill ${statusLower}`}>
                      {statusLower === 'active' && <span className="mini-pulse"></span>}
                      {statusLower.toUpperCase()}
                    </span>
                  </td>

                  {/* Booking code — prefer booking_code, fallback to UUID slice */}
                  <td className="code-cell">
                    <div className="code-container" title={b.id}>
                      {b.booking_code ? (
                        <span className="code-text booking-code-tag">{b.booking_code}</span>
                      ) : (
                        <span className="code-text">...{b.id.slice(-8)}</span>
                      )}
                      <button
                        className={`copy-btn ${copyingId === b.id ? 'copied' : ''}`}
                        onClick={() => copyToClipboard(b.booking_code || b.id, b.id)}
                        title="Copy code"
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
                    <div className="main-time">
                      {new Date(b.created_at).toLocaleTimeString('en-PH', {
                        hour: '2-digit', minute: '2-digit', timeZone: 'Asia/Manila'
                      })}
                    </div>
                    <div className="sub-date">
                      {new Date(b.created_at).toLocaleDateString('en-PH', {
                        month: 'short', day: 'numeric', year: 'numeric', timeZone: 'Asia/Manila'
                      })}
                    </div>
                  </td>

                  <td className="arrival-time-display">
                    <div className="arrival-time" style={{
                      fontWeight: b.arrival_time ? '700' : '400',
                      color: b.arrival_time ? 'var(--primary-deep)' : 'rgba(0,0,0,0.4)'
                    }}>
                      {b.arrival_time
                        ? new Date(b.arrival_time).toLocaleTimeString('en-PH', {
                          hour: '2-digit', minute: '2-digit', timeZone: 'Asia/Manila'
                        })
                        : 'Not set'}
                    </div>
                    <div className="sub-date" style={{ fontSize: '0.75rem', opacity: 0.6 }}>
                      {b.arrival_time
                        ? new Date(b.arrival_time).toLocaleDateString('en-PH', {
                          month: 'short', day: 'numeric', timeZone: 'Asia/Manila'
                        })
                        : ''}
                    </div>
                  </td>

                  {/* Expires At column — only for active table */}
                  {isActiveTable && (
                    <td>
                      <span className={`expiry-tag ${expired ? 'expiry-expired' : 'expiry-active'}`}>
                        {formatExpiry(b)}
                      </span>
                    </td>
                  )}

                  <td className="duration-display">
                    <span className="duration-tag">{b.duration_hours}h</span>
                  </td>

                  <td>
                    <span className={`source-pill ${b.booking_type || 'online'}`}>
                      {(b.booking_type || 'online').toUpperCase()}
                    </span>
                  </td>

                  <td className="amount-cell">
                    <div className="amount-value">₱{b.total_price || 0}</div>
                    <div className="payment-method-label">{b.payment_method || 'Cash'}</div>
                  </td>

                  <td style={{ textAlign: 'right' }}>
                    <div className="labeled-actions">
                      {statusLower === 'active' && (
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
                        onClick={() => {
                          setShowCancelModal({ id: b.id, spotId: b.spot_id });
                          setCancelReason('');
                        }}
                        disabled={statusLower === 'cancelled' || actionLoadingId === b.id}
                      >
                        <span className="btn-icon">✕</span>
                        <span>Cancel</span>
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}

            {list.length === 0 && (
              <tr>
                <td colSpan={isActiveTable ? 10 : 9} className="empty-state">
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

      {/* Filter tabs */}
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

      {/* Active table */}
      {(filterStatus === 'all' || filterStatus === 'active') &&
        renderTable(activeBookingsList, 'Active Reservations', 'Pending arrivals and check-ins', true)
      }

      {/* History table — FIXED: was checking 'confirmed' (wrong), now checks 'completed' */}
      {(filterStatus === 'all' || filterStatus === 'completed' || filterStatus === 'cancelled') &&
        renderTable(historyBookingsList, 'Booking History', 'Processed records and historical logs', false)
      }

      {/* ── Cancel Reason Modal ─────────────────────────────── */}
      {showCancelModal && (
        <div className="cancel-modal-overlay" onClick={(e) => {
          if (e.target === e.currentTarget) { setShowCancelModal(null); setCancelReason(''); }
        }}>
          <div className="cancel-modal-card">
            <h3 className="cancel-modal-title">Cancel Booking</h3>
            <p className="cancel-modal-desc">
              The user will see this cancellation reason in their app.
              You can leave it blank if no reason is needed.
            </p>

            <div className="cancel-reason-field">
              <label className="cancel-reason-label">Reason (optional)</label>
              <textarea
                className="cancel-reason-textarea"
                placeholder="e.g. Double booking, Parking lot under maintenance..."
                value={cancelReason}
                onChange={(e) => setCancelReason(e.target.value)}
                rows={3}
                autoFocus
              />
            </div>

            <div className="cancel-modal-actions">
              <button
                className="btn-action-labeled"
                style={{ opacity: 0.6 }}
                onClick={() => { setShowCancelModal(null); setCancelReason(''); }}
              >
                Keep Booking
              </button>
              <button
                className="btn-action-labeled btn-cancel-labeled"
                onClick={handleCancelConfirm}
                disabled={!!actionLoadingId}
              >
                {actionLoadingId ? '⏳ Cancelling...' : '✕ Confirm Cancel'}
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
