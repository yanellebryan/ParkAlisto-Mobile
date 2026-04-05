'use client'
import { useEffect, useRef, useState } from 'react';
import { supabase } from '@/lib/supabaseClient';
import './components.css';

interface QRScanModalProps {
  onClose: () => void;
}

interface ScannedBooking {
  id: string;
  booking_code: string;
  status: string;
  full_name?: string;
  arrival_time?: string;
  duration_hours: number;
  total_price: number;
  checked_in: boolean;
  checked_in_at?: string;
  parking_spots?: { row_letter: string; spot_number: number; floor: number };
  parking_locations?: { name: string };
}

type ScanState = 'scanning' | 'found' | 'not_found' | 'already_checked_in' | 'error' | 'confirming' | 'success';

export default function QRScanModal({ onClose }: QRScanModalProps) {
  const scannerRef = useRef<HTMLDivElement>(null);
  const html5QrCodeRef = useRef<any>(null);
  const [scanState, setScanState] = useState<ScanState>('scanning');
  const [booking, setBooking] = useState<ScannedBooking | null>(null);
  const [manualCode, setManualCode] = useState('');
  const [useManual, setUseManual] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [cameraError, setCameraError] = useState(false);

  // Start QR scanner on mount
  useEffect(() => {
    if (useManual) return;

    let scanner: any = null;

    const startScanner = async () => {
      try {
        const { Html5Qrcode } = await import('html5-qrcode');
        if (!scannerRef.current) return;

        scanner = new Html5Qrcode('qr-reader');
        html5QrCodeRef.current = scanner;

        await scanner.start(
          { facingMode: 'environment' },
          { fps: 10, qrbox: { width: 250, height: 250 } },
          async (decodedText: string) => {
            // Stop scanning once we have a result
            await scanner.stop().catch(() => {});
            await lookupBooking(decodedText.trim().toUpperCase());
          },
          () => {} // ignore per-frame errors
        );
      } catch (err: any) {
        console.error('Camera start error:', err);
        setCameraError(true);
        setUseManual(true);
      }
    };

    startScanner();

    return () => {
      if (html5QrCodeRef.current) {
        html5QrCodeRef.current.stop().catch(() => {});
      }
    };
  }, [useManual]);

  const lookupBooking = async (code: string) => {
    setScanState('scanning'); // show loading briefly
    try {
      const { data, error } = await supabase
        .from('bookings')
        .select('*, parking_spots(row_letter, spot_number, floor), parking_locations(name)')
        .eq('booking_code', code)
        .maybeSingle();

      if (error) throw error;

      if (!data) {
        setScanState('not_found');
        return;
      }

      const b = data as ScannedBooking;
      setBooking(b);

      if (b.checked_in) {
        setScanState('already_checked_in');
      } else if (b.status !== 'active') {
        setScanState('found'); // still show info, but warn
      } else {
        setScanState('found');
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Unknown error');
      setScanState('error');
    }
  };

  const handleCheckIn = async () => {
    if (!booking) return;
    setScanState('confirming');
    try {
      const { error } = await supabase
        .from('bookings')
        .update({
          checked_in: true,
          checked_in_at: new Date().toISOString(),
        })
        .eq('id', booking.id);

      if (error) throw error;
      setScanState('success');
    } catch (err: any) {
      setErrorMsg(err.message || 'Failed to check in');
      setScanState('error');
    }
  };

  const handleManualLookup = async () => {
    const trimmed = manualCode.trim().toUpperCase();
    if (!trimmed) return;
    // Stop camera if running
    if (html5QrCodeRef.current) {
      await html5QrCodeRef.current.stop().catch(() => {});
    }
    await lookupBooking(trimmed);
  };

  const resetScanner = () => {
    setBooking(null);
    setScanState('scanning');
    setManualCode('');
    setErrorMsg('');
    setUseManual(false);
  };

  const formatTime = (iso?: string) => {
    if (!iso) return 'N/A';
    return new Date(iso).toLocaleString('en-PH', {
      hour: '2-digit', minute: '2-digit',
      month: 'short', day: 'numeric',
      timeZone: 'Asia/Manila'
    });
  };

  return (
    <div className="qr-modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}>
      <div className="qr-modal-card">

        {/* Header */}
        <div className="qr-modal-header">
          <div>
            <h2 className="qr-modal-title">🔍 Scan Entry Pass</h2>
            <p className="qr-modal-subtitle">Scan the user&apos;s QR code to verify their booking</p>
          </div>
          <button className="qr-close-btn" onClick={onClose} title="Close">✕</button>
        </div>

        {/* Scanner / Result area */}
        <div className="qr-content">

          {/* ── Scanning state: camera ─────────────────── */}
          {scanState === 'scanning' && !useManual && (
            <div className="qr-camera-wrapper">
              <div id="qr-reader" ref={scannerRef} className="qr-reader-box" />
              <p className="qr-hint">Point camera at the QR code</p>
              <button
                className="qr-manual-toggle"
                onClick={() => {
                  if (html5QrCodeRef.current) html5QrCodeRef.current.stop().catch(() => {});
                  setUseManual(true);
                }}
              >
                Enter code manually instead
              </button>
            </div>
          )}

          {/* ── Manual input ───────────────────────────── */}
          {(useManual || cameraError) && scanState === 'scanning' && (
            <div className="qr-manual-wrapper">
              {cameraError && (
                <div className="qr-camera-error">
                  📷 Camera unavailable. Please enter the booking code manually.
                </div>
              )}
              <label className="qr-label">Booking Code</label>
              <div className="qr-manual-row">
                <input
                  className="qr-manual-input"
                  placeholder="e.g. PRK-4F2A8B"
                  value={manualCode}
                  onChange={(e) => setManualCode(e.target.value.toUpperCase())}
                  onKeyDown={(e) => e.key === 'Enter' && handleManualLookup()}
                  autoFocus
                />
                <button className="qr-lookup-btn" onClick={handleManualLookup}>
                  Look up →
                </button>
              </div>
              {!cameraError && (
                <button className="qr-manual-toggle" onClick={() => setUseManual(false)}>
                  ← Back to camera
                </button>
              )}
            </div>
          )}

          {/* ── Not found ─────────────────────────────── */}
          {scanState === 'not_found' && (
            <div className="qr-result-state not-found">
              <div className="qr-state-icon">❌</div>
              <h3>Booking Not Found</h3>
              <p>No booking matches this QR code. The code may be invalid or expired.</p>
              <button className="qr-retry-btn" onClick={resetScanner}>Try Again</button>
            </div>
          )}

          {/* ── Error ─────────────────────────────────── */}
          {scanState === 'error' && (
            <div className="qr-result-state error-state">
              <div className="qr-state-icon">⚠️</div>
              <h3>Something went wrong</h3>
              <p>{errorMsg}</p>
              <button className="qr-retry-btn" onClick={resetScanner}>Try Again</button>
            </div>
          )}

          {/* ── Success: checked in ────────────────────── */}
          {scanState === 'success' && booking && (
            <div className="qr-result-state success-state">
              <div className="qr-state-icon success-pulse">✅</div>
              <h3>Checked In!</h3>
              <p>
                <strong>{booking.booking_code}</strong> has been verified.
                {booking.parking_spots && ` Spot ${booking.parking_spots.row_letter}${booking.parking_spots.spot_number}, Floor ${booking.parking_spots.floor}.`}
              </p>
              <p className="qr-checkin-time">Checked in at {formatTime(new Date().toISOString())}</p>
              <button className="qr-retry-btn success" onClick={resetScanner}>Scan Another</button>
            </div>
          )}

          {/* ── Already checked in ────────────────────── */}
          {scanState === 'already_checked_in' && booking && (
            <div className="qr-result-state already-in">
              <div className="qr-state-icon">⚠️</div>
              <h3>Already Checked In</h3>
              <p>This booking was already verified at <strong>{formatTime(booking.checked_in_at)}</strong>.</p>
              <button className="qr-retry-btn" onClick={resetScanner}>Scan Another</button>
            </div>
          )}

          {/* ── Found — confirm check-in ──────────────── */}
          {(scanState === 'found' || scanState === 'confirming') && booking && (
            <div className="qr-booking-card">
              <div className="qr-booking-header">
                <span className="qr-code-tag">{booking.booking_code}</span>
                <span className={`status-pill ${booking.status}`}>{booking.status.toUpperCase()}</span>
              </div>

              {booking.status !== 'active' && (
                <div className="qr-status-warning">
                  ⚠️ This booking is <strong>{booking.status}</strong>. Proceed with caution.
                </div>
              )}

              <div className="qr-booking-details">
                <div className="qr-detail-row">
                  <span className="qr-detail-label">📍 Location</span>
                  <span className="qr-detail-value">{booking.parking_locations?.name || '—'}</span>
                </div>
                <div className="qr-detail-row">
                  <span className="qr-detail-label">🅿️ Spot</span>
                  <span className="qr-detail-value">
                    {booking.parking_spots
                      ? `${booking.parking_spots.row_letter}${booking.parking_spots.spot_number} · Floor ${booking.parking_spots.floor}`
                      : '—'}
                  </span>
                </div>
                <div className="qr-detail-row">
                  <span className="qr-detail-label">⏰ Arrival</span>
                  <span className="qr-detail-value">{formatTime(booking.arrival_time)}</span>
                </div>
                <div className="qr-detail-row">
                  <span className="qr-detail-label">⏱ Duration</span>
                  <span className="qr-detail-value">{booking.duration_hours}h</span>
                </div>
                <div className="qr-detail-row">
                  <span className="qr-detail-label">💰 Amount</span>
                  <span className="qr-detail-value">₱{booking.total_price}</span>
                </div>
              </div>

              <div className="qr-action-row">
                <button className="qr-retry-btn" onClick={resetScanner} disabled={scanState === 'confirming'}>
                  ← Cancel
                </button>
                <button
                  className="qr-checkin-btn"
                  onClick={handleCheckIn}
                  disabled={scanState === 'confirming'}
                >
                  {scanState === 'confirming' ? '⏳ Checking in...' : '✅ Confirm Entry'}
                </button>
              </div>
            </div>
          )}

        </div>
      </div>
    </div>
  );
}
