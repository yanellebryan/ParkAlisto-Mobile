'use client'
import React from 'react';

interface ReceiptProps {
  booking: {
    booking_code: string;
    spot_label: string;
    floor: string;
    arrival_time: string;
    expires_at: string;
    duration_hours: number;
    total_price: number;
  };
}

export default function Receipt({ booking }: ReceiptProps) {
  const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${booking.booking_code}`;

  return (
    <div className="receipt-container printable">
      <div className="receipt-header">
        <h2 className="receipt-title">ParkAlisto</h2>
        <p className="receipt-subtitle">University of St. La Salle</p>
        <div className="receipt-divider"></div>
      </div>

      <div className="receipt-body">
        <div className="qr-section">
          <img src={qrUrl} alt="Booking QR Code" className="receipt-qr" />
          <div className="booking-code">{booking.booking_code}</div>
        </div>

        <div className="receipt-details">
          <div className="detail-row">
            <span>Spot:</span>
            <strong>{booking.spot_label || 'N/A'} (FL {booking.floor || '1'})</strong>
          </div>
          <div className="detail-row">
            <span>Entry:</span>
            <span>{booking.arrival_time ? new Date(booking.arrival_time).toLocaleString('en-PH', { timeZone: 'Asia/Manila', hour: '2-digit', minute: '2-digit', month: 'short', day: 'numeric' }) : 'N/A'}</span>
          </div>
          <div className="detail-row">
            <span>Valid Until:</span>
            <span>{booking.expires_at ? new Date(booking.expires_at).toLocaleString('en-PH', { timeZone: 'Asia/Manila', hour: '2-digit', minute: '2-digit', month: 'short', day: 'numeric' }) : 'N/A'}</span>
          </div>
          <div className="detail-row">
            <span>Duration:</span>
            <span>{booking.duration_hours || 0} Hr(s)</span>
          </div>
          <div className="receipt-divider"></div>
          <div className="detail-row total">
            <span>TOTAL PAID:</span>
            <strong>₱{booking.total_price || 0}</strong>
          </div>
        </div>
      </div>

      <div className="receipt-footer">
        <div className="receipt-divider"></div>
        <p>Thank you for choosing ParkAlisto!</p>
        <p className="footer-timestamp">{new Date().toLocaleString('en-PH', { timeZone: 'Asia/Manila', hour: '2-digit', minute: '2-digit' })}</p>
      </div>

      <style jsx>{`
        .receipt-container {
          width: 58mm;
          padding: 2mm;
          background: #fff;
          color: #000;
          font-family: 'Courier New', Courier, monospace;
          text-align: center;
          margin: 0 auto;
          border: 1px solid #eee; /* Light border on screen to see it */
        }
        .receipt-header {
          margin-bottom: 2mm;
        }
        .receipt-title {
          margin: 0;
          font-size: 1.4rem;
          font-weight: bold;
        }
        .receipt-subtitle {
          margin: 0;
          font-size: 0.75rem;
          text-transform: uppercase;
        }
        .receipt-divider {
          border-top: 1px dashed #000;
          margin: 3mm 0;
          width: 100%;
        }
        .receipt-qr {
          width: 35mm;
          height: 35mm;
          margin: 0 auto 2mm;
          display: block;
        }
        .booking-code {
          font-size: 1.1rem;
          font-weight: bold;
          letter-spacing: 1px;
          margin-top: 1mm;
        }
        .receipt-details {
          text-align: left;
          font-size: 0.85rem;
          margin-top: 3mm;
          padding: 0 1mm;
        }
        .detail-row {
          display: flex;
          justify-content: space-between;
          margin-bottom: 1mm;
        }
        .detail-row strong {
          text-align: right;
        }
        .detail-row.total {
          font-size: 1.1rem;
          margin-top: 2mm;
          font-weight: bold;
        }
        .receipt-footer {
          margin-top: 3mm;
          font-size: 0.7rem;
        }
        .footer-timestamp {
          font-size: 0.6rem;
          opacity: 0.7;
          margin-top: 1.5mm;
        }
        
        @media screen {
           .printable {
             display: none; /* Keep hidden on screen */
           }
        }
        
        @media print {
          @page {
            size: 58mm auto;
            margin: 0;
          }
          :global(body *) {
            visibility: hidden !important;
          }
          .printable, :global(.printable *) {
            visibility: visible !important;
          }
          .printable {
            position: absolute !important;
            left: 0 !important;
            top: 0 !important;
            width: 58mm !important;
            border: none !important;
            padding: 0 !important;
            margin: 0 !important;
            display: block !important;
          }
        }
      `}</style>
    </div>
  );
}
