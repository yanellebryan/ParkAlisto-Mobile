'use client'
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import './components.css';

export default function Sidebar() {
  const pathname = usePathname();

  const handleSignOut = () => {
    localStorage.removeItem('admin_auth');
    window.location.href = '/login';
  };

  const navItems = [
    { href: '/', label: 'Dashboard', icon: '⊞' },
    { href: '/reservations', label: 'Reservations', icon: '📅' },
    { href: '/walk-in', label: 'Walk-in Booking', icon: '🎟️' },
    { href: '/scanner', label: 'Entry Pass', icon: '🔍' },
    { href: '/exit-scanner', label: 'Exit Pass', icon: '🚪' },
    { href: '/settings', label: 'Settings', icon: '⚙️' },
  ];

  return (
    <aside className="sidebar glass">
      <div className="brand">
        <img src="/logo.png" alt="ParkAlisto Logo" className="brand-logo" />
      </div>
      
      <nav className="nav-menu">
        <ul className="nav-list" style={{ listStyle: 'none', padding: 0 }}>
          {navItems.map((item) => {
            const isActive = pathname === item.href;
            return (
              <li key={item.href} className={`nav-item ${isActive ? 'active' : ''}`}>
                <Link href={item.href} className="nav-link">
                  <span className="icon">{item.icon}</span> {item.label}
                  {isActive && <div className="active-indicator" />}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>

      <div className="sidebar-footer">
        <button className="btn btn-outline full-width" onClick={handleSignOut}>Sign Out</button>
      </div>
    </aside>
  );
}
