'use client'
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabaseClient';
import './components.css';

export default function SummaryBar() {
  const [counts, setCounts] = useState({
    total: 0,
    active: 0,
    cancelled: 0,
    pending: 0
  });

  useEffect(() => {
    const fetchCounts = async () => {
      const { data, error } = await supabase
        .from('bookings')
        .select('status');

      if (error) {
        console.error('Error fetching counts for summary:', error);
        return;
      }

    if (data) {
      setCounts({
        total: data.length,
        active: data.filter(b => (b.status || '').toLowerCase() === 'active').length,
        cancelled: data.filter(b => (b.status || '').toLowerCase() === 'cancelled').length,
        pending: data.filter(b => (b.status || '').toLowerCase() === 'completed').length // Using 'pending' slot for Completed count
      });
    }
  };

  fetchCounts();
  
  // 1. WebSocket Channel (Realtime Push)
  const channel = supabase
    .channel('summary_stats_monitoring')
    .on('postgres_changes', { 
      event: '*', 
      schema: 'public', 
      table: 'bookings' 
    }, () => {
      fetchCounts();
    })
    .subscribe();

  // 2. Poll fallback (Pull every 5 seconds)
  const pollInterval = setInterval(() => {
    fetchCounts();
  }, 5000);

  return () => {
    supabase.removeChannel(channel);
    clearInterval(pollInterval);
  };
}, []);

return (
  <div className="summary-bar fade-in-up">
    <div className="summary-item total">
      <div className="summary-label">Total Volume</div>
      <div className="summary-value">{counts.total}</div>
    </div>
    <div className="summary-item active">
      <div className="summary-label">Incoming (Active)</div>
      <div className="summary-value">{counts.active}</div>
    </div>
    <div className="summary-item completed">
      <div className="summary-label">Completed</div>
      <div className="summary-value">{counts.pending}</div>
    </div>
    <div className="summary-item cancelled">
      <div className="summary-label">Cancelled</div>
      <div className="summary-value">{counts.cancelled}</div>
    </div>
  </div>
);
}
