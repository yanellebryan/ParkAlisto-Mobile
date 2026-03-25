'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Sidebar from '@/components/Sidebar'
import LiveMap from '@/components/LiveMap'
import SummaryBar from '@/components/SummaryBar'
import './dashboard.css'

export default function Dashboard() {
  const router = useRouter();
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    // Basic check: in a real app, this would check Supabase session or a secure cookie
    const auth = localStorage.getItem('admin_auth');
    if (auth === 'true') {
      setIsAuthenticated(true);
    } else {
      router.push('/login');
    }
  }, [router]);

  if (!isAuthenticated) return null; // Avoid flicker
  return (
    <div className="layout">
      <Sidebar />
      <main className="main-content">
        <header className="header glass">
          <div className="header-wrapper">
            <img src="/usls_logo.png" alt="USLS Logo" className="usls-header-logo" />
            <div className="header-titles">
              <h1>Parking Command Center</h1>
              <p className="subtitle">University of St. La Salle • Real-time Monitoring</p>
            </div>
          </div>
          <div className="admin-profile">
            <span className="glass-badge">● Live System</span>
            <div className="avatar">AD</div>
          </div>
        </header>

        <div className="dashboard-grid standalone">
          <section className="summary-section fade-in-up">
            <SummaryBar />
          </section>

          <section className="map-section glass fade-in-up delay-1">
            <div className="section-header">
              <h2>Overview Map</h2>
              <div className="legend">
                <span className="legend-item"><span className="dot dot-free"></span> Available</span>
                <span className="legend-item"><span className="dot dot-occupied"></span> Occupied</span>
              </div>
            </div>
            <LiveMap />
          </section>
        </div>
      </main>
    </div>
  )
}
