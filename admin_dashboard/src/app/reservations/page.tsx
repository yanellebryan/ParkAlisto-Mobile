'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Sidebar from '@/components/Sidebar'
import BookingsTable from '@/components/BookingsTable'
import SummaryBar from '@/components/SummaryBar'
import '../dashboard.css'

export default function ReservationsPage() {
  const router = useRouter();
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    const auth = localStorage.getItem('admin_auth');
    if (auth === 'true') {
      setIsAuthenticated(true);
    } else {
      router.push('/login');
    }
  }, [router]);

  if (!isAuthenticated) return null;

  return (
    <div className="layout">
      <Sidebar />
      <main className="main-content">
        <header className="header glass">
          <div className="header-wrapper">
             <img src="/usls_logo.png" alt="USLS Logo" className="usls-header-logo" />
             <div className="header-titles">
                <h1>Reservations Management</h1>
                <p className="subtitle">University of St. La Salle • Booking Records</p>
             </div>
          </div>
          <div className="admin-profile">
            <span className="glass-badge">● Live System</span>
            <div className="avatar">AD</div>
          </div>
        </header>

        <div className="reservations-content fade-in-up">
           <SummaryBar />
           <section className="bookings-section-full" style={{ marginTop: '24px' }}>
              <BookingsTable />
           </section>
        </div>
      </main>
    </div>
  )
}
