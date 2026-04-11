'use client'
import { useEffect, useRef, useState, useCallback } from 'react';
import { supabase } from '@/lib/supabaseClient';
import '@/components/components.css';

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
  spot_id?: string;
  parking_spots?: { row_letter: string; spot_number: number; floor: number };
  parking_locations?: { name: string };
}

type ScanState =
  | 'idle'
  | 'scanning'
  | 'found'
  | 'not_found'
  | 'not_checked_in'
  | 'already_completed'
  | 'error'
  | 'confirming'
  | 'success';

export default function ExitScannerPage() {
  // ── State ──────────────────────────────────────────────────
  const [mode, setMode] = useState<'manual' | 'camera'>('manual');
  const [scanState, setScanState] = useState<ScanState>('idle');
  const [booking, setBooking] = useState<ScannedBooking | null>(null);
  const [manualCode, setManualCode] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  const [cameraSupported, setCameraSupported] = useState<boolean | null>(null);
  const [cameraError, setCameraError] = useState('');
  const [cameras, setCameras] = useState<{ id: string; label: string }[]>([]);
  const [selectedCameraId, setSelectedCameraId] = useState<string>('');

  const scannerRef = useRef<HTMLDivElement>(null);
  const html5QrCodeRef = useRef<any>(null);
  const scannerStartedRef = useRef(false);

  // ── Camera availability check ──────────────────────────────
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
        // Ignore stop errors
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

        // Initialize scanner if not already there
        if (!html5QrCodeRef.current) {
          html5QrCodeRef.current = new Html5Qrcode('exit-qr-scan-viewport');
        }
        const scanner = html5QrCodeRef.current;

        // Fetch cameras if we don't have them yet
        let availableCameras = cameras;
        if (availableCameras.length === 0) {
          try {
            const devices = await Html5Qrcode.getCameras();
            if (devices && devices.length > 0) {
              setCameras(devices);
              availableCameras = devices;
              if (!selectedCameraId) {
                // Try to find environment camera by default, else use first one
                const env = devices.find(
                  (d) =>
                    d.label.toLowerCase().includes('back') ||
                    d.label.toLowerCase().includes('environment')
                );
                setSelectedCameraId(env ? env.id : devices[0].id);
              }
            }
          } catch (camErr) {
            console.warn('Failed to list cameras', camErr);
          }
        }

        // Determine target camera
        const cameraConfig = selectedCameraId ? selectedCameraId : { facingMode: 'environment' };

        try {
          await scanner.start(
            cameraConfig,
            { fps: 10, qrbox: { width: 240, height: 240 } },
            async (decoded: string) => {
              await stopCamera();
              await lookupBooking(decoded.trim().toUpperCase());
            },
            () => {}
          );
          if (!cancelled) {
            scannerStartedRef.current = true;
            setCameraError('');
            setCameraSupported(true);
          }
        } catch (startErr: any) {
          if (cancelled) return;
          // Fallback to first camera if specifically environment failed
          if (!selectedCameraId && availableCameras.length > 0) {
            await scanner.start(
              availableCameras[0].id,
              { fps: 10, qrbox: { width: 240, height: 240 } },
              async (decoded: string) => {
                await stopCamera();
                await lookupBooking(decoded.trim().toUpperCase());
              },
              () => {}
            );
            if (!cancelled) {
              scannerStartedRef.current = true;
              setSelectedCameraId(availableCameras[0].id);
              setCameraError('');
            }
          } else {
            throw startErr;
          }
        }
      } catch (err: any) {
        if (cancelled) return;
        const msg = err?.message || String(err);
        const isNoCamera =
          msg.includes('NotFound') ||
          msg.includes('not found') ||
          msg.includes('Requested device');
        const isPermission = msg.includes('NotAllowed') || msg.includes('permission');

        setCameraError(
          isPermission
            ? 'Camera permission denied. Please allow camera access in your browser settings.'
            : isNoCamera
              ? 'No camera found on this device. Use manual entry below.'
              : `Camera error: ${msg}`
        );
        if (isNoCamera) setCameraSupported(false);
        setMode('manual');
      }
    };

    startScanner();

    return () => {
      cancelled = true;
      stopCamera();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mode, selectedCameraId]);

  // ── Lookup booking by code ────────────────────────────────
  const lookupBooking = async (code: string) => {
    setScanState('scanning');
    setBooking(null);

    try {
      const { data, error } = await supabase
        .from('bookings')
        .select(
          '*, spot_id, parking_spots(row_letter, spot_number, floor), parking_locations(name)'
        )
        .eq('booking_code', code)
        .maybeSingle();

      if (error) throw error;

      if (!data) {
        setScanState('not_found');
        return;
      }

      const b = data as ScannedBooking;
      setBooking(b);

      const statusLower = (b.status || '').toLowerCase();

      if (statusLower === 'completed' || statusLower === 'cancelled') {
        setScanState('already_completed');
      } else if (!b.checked_in) {
        setScanState('not_checked_in');
      } else {
        setScanState('found');
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Unknown error');
      setScanState('error');
    }
  };

  // ── Confirm check-out ─────────────────────────────────────
  const handleCheckOut = async () => {
    if (!booking) return;
    setScanState('confirming');

    try {
      // 1. Mark booking as completed
      const { error: bookingError } = await supabase
        .from('bookings')
        .update({ status: 'completed' })
        .eq('id', booking.id);

      if (bookingError) throw bookingError;

      // 2. Free up the parking spot
      if (booking.spot_id) {
        const { error: spotError } = await supabase
          .from('parking_spots')
          .update({ status: 'available' })
          .eq('id', booking.spot_id);

        if (spotError) console.error('Failed to free spot:', spotError);
      }

      setScanState('success');
    } catch (err: any) {
      setErrorMsg(err.message || 'Failed to check out');
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
    if (mode === 'camera') setMode('manual');
  };

  const formatTime = (iso?: string) => {
    if (!iso) return 'N/A';
    return new Date(iso).toLocaleString('en-PH', {
      hour: '2-digit',
      minute: '2-digit',
      month: 'short',
      day: 'numeric',
      timeZone: 'Asia/Manila',
    });
  };

  return (
    <div className="qr-modal-overlay" style={{ background: '#f0fdf4', minHeight: '100vh' }}>
      <div className="qr-modal-card" style={{ borderTop: '4px solid #16a34a' }}>

        {/* Header */}
        <div className="qr-modal-header">
          <div>
            <h2 className="qr-modal-title">🚪 Scan Exit Pass</h2>
            <p className="qr-modal-subtitle">
              Verify a user&apos;s exit and release the parking spot
            </p>
          </div>
        </div>

        <div className="qr-content">

          {/* ── Mode tabs ────────────────────────────────── */}
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

          {/* ── Manual input ────────────────────────────── */}
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
                Ask the user to show the booking code from their app.
              </p>
            </div>
          )}

          {/* ── Camera mode ──────────────────────────────── */}
          {mode === 'camera' && (scanState === 'idle' || scanState === 'scanning') && (
            <div className="qr-camera-wrapper">
              {cameras.length > 1 && (
                <div className="qr-camera-controls">
                  <select
                    className="qr-camera-select"
                    value={selectedCameraId}
                    onChange={(e) => {
                      stopCamera();
                      setSelectedCameraId(e.target.value);
                    }}
                  >
                    {cameras.map((cam) => (
                      <option key={cam.id} value={cam.id}>
                        {cam.label || `Camera ${cam.id.slice(0, 5)}`}
                      </option>
                    ))}
                  </select>
                </div>
              )}
              <div id="exit-qr-scan-viewport" ref={scannerRef} className="qr-reader-box" />
              <p className="qr-hint">Point the webcam at the user&apos;s QR code</p>
            </div>
          )}

          {/* ── Loading ────────────────────────────────── */}
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
              <p>
                No booking matches <strong>{manualCode || 'that code'}</strong>. Double-check the
                code and try again.
              </p>
              <button className="qr-retry-btn" onClick={resetModal}>Try Again</button>
            </div>
          )}

          {/* ── Not checked in ────────────────────────── */}
          {scanState === 'not_checked_in' && booking && (
            <div className="qr-result-state already-checked-in">
              <div className="qr-state-icon">⚠️</div>
              <h3>User Hasn&apos;t Entered Yet</h3>
              <p>
                <strong>{booking.booking_code}</strong> has not been checked in at the entrance.
                Please use the Entry Pass scanner first.
              </p>
              <button className="qr-retry-btn" onClick={resetModal}>Scan Another</button>
            </div>
          )}

          {/* ── Already completed / cancelled ─────────── */}
          {scanState === 'already_completed' && booking && (
            <div className="qr-result-state not-found">
              <div className="qr-state-icon">ℹ️</div>
              <h3>Booking Already {booking.status.charAt(0).toUpperCase() + booking.status.slice(1)}</h3>
              <p>
                <strong>{booking.booking_code}</strong> has already been{' '}
                <strong>{booking.status}</strong>. No action needed.
              </p>
              <button className="qr-retry-btn" onClick={resetModal}>Scan Another</button>
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

          {/* ── Success ───────────────────────────────── */}
          {scanState === 'success' && booking && (
            <div className="qr-result-state success-state">
              <div className="qr-state-icon success-pulse">✅</div>
              <h3>Exit Confirmed!</h3>
              <p>
                <strong>{booking.booking_code}</strong> has been marked as completed.
                {booking.parking_spots && (
                  <>
                    {' '}Spot{' '}
                    <strong>
                      {booking.parking_spots.row_letter}
                      {booking.parking_spots.spot_number}
                    </strong>
                    , Floor {booking.parking_spots.floor} is now <strong>available</strong>.
                  </>
                )}
              </p>
              <p className="qr-checkin-time">
                Checked out at {formatTime(new Date().toISOString())}
              </p>
              <button className="qr-retry-btn success" onClick={resetModal}>Scan Another</button>
            </div>
          )}

          {/* ── Found — booking details + confirm ─────── */}
          {(scanState === 'found' || scanState === 'confirming') && booking && (
            <div className="qr-booking-card">
              <div className="qr-booking-header">
                <span className="qr-code-tag">{booking.booking_code}</span>
                <span className={`status-pill ${booking.status}`}>
                  {booking.status.toUpperCase()}
                </span>
              </div>

              {/* Checked-in badge */}
              <div style={{
                display: 'inline-flex', alignItems: 'center', gap: '6px',
                background: '#dcfce7', color: '#15803d', borderRadius: '6px',
                padding: '4px 10px', fontSize: '0.8rem', fontWeight: 600,
                marginBottom: '12px'
              }}>
                ✅ Checked in at {formatTime(booking.checked_in_at)}
              </div>

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
                  style={{ background: 'linear-gradient(135deg, #16a34a, #22c55e)' }}
                  onClick={handleCheckOut}
                  disabled={scanState === 'confirming'}
                >
                  {scanState === 'confirming' ? '⏳ Processing…' : '🚪 Confirm Exit'}
                </button>
              </div>
            </div>
          )}

        </div>
      </div>
    </div>
  );
}
