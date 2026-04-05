'use client'
import { useEffect, useRef, useState, useCallback } from 'react';
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

type ScanState = 'idle' | 'scanning' | 'found' | 'not_found' | 'already_checked_in' | 'error' | 'confirming' | 'success';

export default function QRScanModal({ onClose }: QRScanModalProps) {
  // ── State ──────────────────────────────────────────────────
  const [mode, setMode] = useState<'manual' | 'camera'>('manual'); // Default: manual
  const [scanState, setScanState] = useState<ScanState>('idle');
  const [booking, setBooking] = useState<ScannedBooking | null>(null);
  const [manualCode, setManualCode] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  const [cameraSupported, setCameraSupported] = useState<boolean | null>(null);
  const [cameraError, setCameraError] = useState('');

  const scannerRef = useRef<HTMLDivElement>(null);
  const html5QrCodeRef = useRef<any>(null);
  const scannerStartedRef = useRef(false); // Track if scanner actually started

  // ── Camera availability check (non-blocking) ──────────────
  useEffect(() => {
    const checkCamera = async () => {
      try {
        const devices = await navigator.mediaDevices.enumerateDevices();
        const hasCamera = devices.some(d => d.kind === 'videoinput');
        setCameraSupported(hasCamera);
      } catch {
        setCameraSupported(false);
      }
    };
    if (navigator.mediaDevices) {
      checkCamera();
    } else {
      setCameraSupported(false);
    }
  }, []);

  // ── Stop camera safely ─────────────────────────────────────
  const stopCamera = useCallback(async () => {
    if (html5QrCodeRef.current && scannerStartedRef.current) {
      try {
        await html5QrCodeRef.current.stop();
      } catch {
        // Ignore stop errors — scanner may already be stopped
      }
      scannerStartedRef.current = false;
    }
    html5QrCodeRef.current = null;
  }, []);

  // ── Start camera scanner ───────────────────────────────────
  useEffect(() => {
    if (mode !== 'camera') return;

    let cancelled = false;

    const startScanner = async () => {
      try {
        const { Html5Qrcode } = await import('html5-qrcode');
        if (cancelled || !scannerRef.current) return;

        const scanner = new Html5Qrcode('qr-scan-viewport');
        html5QrCodeRef.current = scanner;

        await scanner.start(
          { facingMode: 'environment' },
          { fps: 10, qrbox: { width: 240, height: 240 } },
          async (decoded: string) => {
            await stopCamera();
            const trimmed = decoded.trim().toUpperCase();
            await lookupBooking(trimmed);
          },
          () => { } // per-frame errors — ignore
        );

        if (!cancelled) {
          scannerStartedRef.current = true;
          setCameraError('');
        }
      } catch (err: any) {
        if (cancelled) return;
        const msg = err?.message || String(err);
        const isNoCamera = msg.includes('NotFound') || msg.includes('not found') || msg.includes('Requested device');
        setCameraError(isNoCamera
          ? 'No camera found on this device. Use manual entry below.'
          : `Camera error: ${msg}`
        );
        setCameraSupported(isNoCamera ? false : cameraSupported);
        // Fall back to manual
        setMode('manual');
      }
    };

    startScanner();

    return () => {
      cancelled = true;
      stopCamera();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mode]);

  // ── Lookup booking by code ────────────────────────────────
  const lookupBooking = async (code: string) => {
    setScanState('scanning');
    setBooking(null);

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

      setBooking(data as ScannedBooking);
      setScanState(data.checked_in ? 'already_checked_in' : 'found');
    } catch (err: any) {
      setErrorMsg(err.message || 'Unknown error');
      setScanState('error');
    }
  };

  // ── Confirm check-in ──────────────────────────────────────
  const handleCheckIn = async () => {
    if (!booking) return;
    setScanState('confirming');
    try {
      const { error } = await supabase
        .from('bookings')
        .update({ checked_in: true, checked_in_at: new Date().toISOString() })
        .eq('id', booking.id);

      if (error) throw error;
      setScanState('success');
    } catch (err: any) {
      setErrorMsg(err.message || 'Failed to check in');
      setScanState('error');
    }
  };

  // ── Manual lookup ─────────────────────────────────────────
  const handleManualLookup = async () => {
    const trimmed = manualCode.trim().toUpperCase();
    if (!trimmed) return;
    await lookupBooking(trimmed);
  };

  // ── Reset ─────────────────────────────────────────────────
  const resetModal = () => {
    setBooking(null);
    setScanState('idle');
    setManualCode('');
    setErrorMsg('');
    if (mode === 'camera') {
      setMode('manual'); // Return to manual after a scan result
    }
  };

  const formatTime = (iso?: string) => {
    if (!iso) return 'N/A';
    return new Date(iso).toLocaleString('en-PH', {
      hour: '2-digit', minute: '2-digit',
      month: 'short', day: 'numeric',
      timeZone: 'Asia/Manila'
    });
  };

  // ── Render ────────────────────────────────────────────────
  return (
    <div className="qr-modal-overlay" onClick={(e) => {
      if (e.target === e.currentTarget) { stopCamera(); onClose(); }
    }}>
      <div className="qr-modal-card">

        {/* Header */}
        <div className="qr-modal-header">
          <div>
            <h2 className="qr-modal-title">🔍 Scan Entry Pass</h2>
            <p className="qr-modal-subtitle">Verify a user&apos;s parking booking at the entrance</p>
          </div>
          <button className="qr-close-btn" onClick={() => { stopCamera(); onClose(); }} title="Close">✕</button>
        </div>

        <div className="qr-content">

          {/* ── Mode tabs: Manual / Camera ─────────────── */}
          {(scanState === 'idle' || scanState === 'not_found' || scanState === 'scanning') && (
            <div className="qr-mode-tabs">
              <button
                className={`qr-mode-tab ${mode === 'manual' ? 'active' : ''}`}
                onClick={() => { stopCamera(); setMode('manual'); }}
              >
                ⌨️ Enter Code
              </button>
              <button
                className={`qr-mode-tab ${mode === 'camera' ? 'active' : ''} ${cameraSupported === false ? 'disabled' : ''}`}
                onClick={() => {
                  if (cameraSupported === false) return;
                  setMode('camera');
                }}
                title={cameraSupported === false ? 'No camera available on this device' : 'Scan QR with camera'}
              >
                📷 Use Camera
                {cameraSupported === false && <span className="qr-tab-badge">N/A</span>}
              </button>
            </div>
          )}

          {/* Camera error notice */}
          {cameraError && (
            <div className="qr-camera-error" style={{ marginBottom: '12px' }}>
              📷 {cameraError}
            </div>
          )}

          {/* ── Manual input ───────────────────────────── */}
          {mode === 'manual' && (scanState === 'idle' || scanState === 'not_found') && (
            <div className="qr-manual-wrapper" style={{ marginTop: '4px' }}>
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
                <button
                  className="qr-lookup-btn"
                  onClick={handleManualLookup}
                  disabled={!manualCode.trim()}
                >
                  Look up →
                </button>
              </div>
              <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', margin: '6px 0 0' }}>
                Ask the user to read the code from their app or show their QR screen.
              </p>
            </div>
          )}

          {/* ── Camera mode ────────────────────────────── */}
          {mode === 'camera' && (scanState === 'idle' || scanState === 'scanning') && (
            <div className="qr-camera-wrapper">
              <div id="qr-scan-viewport" ref={scannerRef} className="qr-reader-box" />
              <p className="qr-hint">Point the webcam at the user&apos;s QR code</p>
            </div>
          )}

          {/* ── Loading ─────────────────────────────────── */}
          {scanState === 'scanning' && (
            <div className="qr-result-state">
              <div className="qr-state-icon">⏳</div>
              <h3>Looking up booking…</h3>
            </div>
          )}

          {/* ── Not found ─────────────────────────────── */}
          {scanState === 'not_found' && (
            <div className="qr-result-state not-found">
              <div className="qr-state-icon">❌</div>
              <h3>Booking Not Found</h3>
              <p>No booking matches <strong>{manualCode || 'that code'}</strong>. Double-check the code and try again.</p>
              <button className="qr-retry-btn" onClick={resetModal}>Try Again</button>
            </div>
          )}

          {/* ── Error ────────────────────────────────── */}
          {scanState === 'error' && (
            <div className="qr-result-state">
              <div className="qr-state-icon">⚠️</div>
              <h3>Something went wrong</h3>
              <p>{errorMsg}</p>
              <button className="qr-retry-btn" onClick={resetModal}>Try Again</button>
            </div>
          )}

          {/* ── Already checked in ────────────────────── */}
          {scanState === 'already_checked_in' && booking && (
            <div className="qr-result-state already-checked-in">
              <div className="qr-state-icon">⚠️</div>
              <h3>Already Checked In</h3>
              <p>
                <strong>{booking.booking_code}</strong> was already verified
                at <strong>{formatTime(booking.checked_in_at)}</strong>.
              </p>
              <button className="qr-retry-btn" onClick={resetModal}>Scan Another</button>
            </div>
          )}

          {/* ── Success ───────────────────────────────── */}
          {scanState === 'success' && booking && (
            <div className="qr-result-state success-state">
              <div className="qr-state-icon success-pulse">✅</div>
              <h3>Checked In!</h3>
              <p>
                <strong>{booking.booking_code}</strong> successfully verified.
                {booking.parking_spots && (
                  <> Spot <strong>{booking.parking_spots.row_letter}{booking.parking_spots.spot_number}</strong>, Floor {booking.parking_spots.floor}.</>
                )}
              </p>
              <p className="qr-checkin-time">Checked in at {formatTime(new Date().toISOString())}</p>
              <button className="qr-retry-btn success" onClick={resetModal}>Scan Another</button>
            </div>
          )}

          {/* ── Found — booking details + confirm ─────── */}
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
                <button
                  className="qr-retry-btn"
                  onClick={resetModal}
                  disabled={scanState === 'confirming'}
                >
                  ← Back
                </button>
                <button
                  className="qr-checkin-btn"
                  onClick={handleCheckIn}
                  disabled={scanState === 'confirming'}
                >
                  {scanState === 'confirming' ? '⏳ Checking in…' : '✅ Confirm Entry'}
                </button>
              </div>
            </div>
          )}

        </div>
      </div>
    </div>
  );
}
