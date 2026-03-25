import Link from 'next/link';
import './components.css';

export default function Sidebar() {
  const handleSignOut = () => {
    localStorage.removeItem('admin_auth');
    window.location.href = '/login';
  };

  return (
    <aside className="sidebar glass">
      <div className="brand">
        <div className="logo-icon">P</div>
        <h2>ParkAlisto</h2>
      </div>
      
      <nav className="nav-menu">
        <ul className="nav-list">
          <li className="nav-item active">
            <Link href="/" className="nav-link">
              <span className="icon">⊞</span> Dashboard
            </Link>
          </li>
          <li className="nav-item">
            <Link href="/reservations" className="nav-link">
              <span className="icon">📅</span> Reservations
            </Link>
          </li>
          <li className="nav-item">
            <Link href="/users" className="nav-link">
              <span className="icon">👥</span> Users
            </Link>
          </li>
          <li className="nav-item">
            <Link href="/settings" className="nav-link">
              <span className="icon">⚙️</span> Settings
            </Link>
          </li>
        </ul>
      </nav>

      <div className="sidebar-footer">
        <button className="btn btn-outline full-width" onClick={handleSignOut}>Sign Out</button>
      </div>
    </aside>
  );
}
