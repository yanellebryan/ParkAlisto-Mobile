'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Sidebar from '@/components/Sidebar'
import LiveMap from '@/components/LiveMap'
import BookingsTable from '@/components/BookingsTable'
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
          <div className="header-titles">
            <h1>USLS Parking Command Center</h1>
            <p className="subtitle">Real-time spot monitoring and access control</p>
          </div>
          <div className="admin-profile">
            <span className="glass-badge">● Live System</span>
            <div className="avatar">AD</div>
          </div>
        </header>

        <div className="dashboard-grid">
          <section className="map-section glass fade-in-up">
            <div className="section-header">
              <h2>Overview Map</h2>
              <div className="legend">
                <span className="legend-item"><span className="dot dot-free"></span> Available</span>
                <span className="legend-item"><span className="dot dot-occupied"></span> Occupied</span>
              </div>
            </div>
            <LiveMap />
          </section>
          
          <section className="bookings-section fade-in-up delay-1">
            <BookingsTable />
          </section>
        </div>
      </main>
    </div>
  )
}
