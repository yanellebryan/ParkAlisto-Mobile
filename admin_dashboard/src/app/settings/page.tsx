'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Sidebar from '@/components/Sidebar'
import '../dashboard.css'
import '@/components/components.css'

export default function SettingsPage() {
  const router = useRouter();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [saving, setSaving] = useState(false);
  const [showSaved, setShowSaved] = useState(false);

  // Settings state
  const [settings, setSettings] = useState({
    admin: {
      name: 'Admin User',
      email: 'admin@usls.edu',
    },
    parking: {
      name: 'University of St. La Salle Parking',
      operatingHours: '06:00 AM - 10:00 PM',
      hourlyRate: 50,
      maxDuration: 8,
    },
    behavior: {
      enableBookings: true,
      allowCancellations: true,
      gracePeriod: 15,
    },
    display: {
      showLabels: true,
      showPrices: true,
      defaultZoom: 15,
    },
    system: {
      timezone: 'Asia/Manila',
      currency: 'PHP',
      timeFormat: '12h',
    }
  });

  useEffect(() => {
    const auth = localStorage.getItem('admin_auth');
    if (auth === 'true') {
      setIsAuthenticated(true);
      // Load saved settings
      const saved = localStorage.getItem('admin_settings');
      if (saved) {
        try {
          setSettings(JSON.parse(saved));
        } catch (e) {
          console.error('Error parsing settings:', e);
        }
      }
    } else {
      router.push('/login');
    }
  }, [router]);

  const handleSave = () => {
    setSaving(true);
    localStorage.setItem('admin_settings', JSON.stringify(settings));
    setTimeout(() => {
      setSaving(false);
      setShowSaved(true);
      setTimeout(() => setShowSaved(false), 2000);
    }, 800);
  };

  const handleSignOut = () => {
    localStorage.removeItem('admin_auth');
    router.push('/login');
  };

  const updateSetting = (category: string, key: string, value: any) => {
    setSettings(prev => ({
      ...prev,
      [category]: {
        //@ts-ignore
        ...prev[category],
        [key]: value
      }
    }));
  };

  if (!isAuthenticated) return null;

  return (
    <div className="layout">
      <Sidebar />
      <main className="main-content">
        <header className="header glass">
          <div className="header-wrapper">
             <div className="header-titles">
                <h1>Admin Settings</h1>
                <p className="subtitle">Configure your dashboard and parking preferences</p>
             </div>
          </div>
          <div className="admin-profile">
            {showSaved && <span className="glass-badge" style={{ background: 'var(--primary-glow)', marginRight: '16px' }}>✓ Saved to Local Storage</span>}
            <button className={`btn ${saving ? 'loading' : 'btn-primary'}`} onClick={handleSave} disabled={saving}>
              {saving ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </header>

        <div className="settings-grid fade-in-up">
          {/* Admin Profile */}
          <section className="settings-card glass">
            <h3><span>👤</span> Admin Profile</h3>
            <div className="profile-header">
              <div className="profile-avatar-large">AD</div>
              <div>
                <p className="setting-title">{settings.admin.name}</p>
                <p className="setting-desc">Primary Administrator Account</p>
              </div>
            </div>
            <div className="settings-section">
              <div className="form-group">
                <label>Display Name</label>
                <input 
                  type="text" 
                  value={settings.admin.name} 
                  onChange={(e) => updateSetting('admin', 'name', e.target.value)} 
                />
              </div>
              <div className="form-group">
                <label>Email Address</label>
                <input 
                  type="email" 
                  value={settings.admin.email} 
                  onChange={(e) => updateSetting('admin', 'email', e.target.value)} 
                />
              </div>
            </div>
          </section>

          {/* Parking Settings */}
          <section className="settings-card glass">
            <h3><span>🅿️</span> Parking Settings</h3>
            <div className="settings-section">
              <div className="form-group">
                <label>Parking Name</label>
                <input 
                  type="text" 
                  value={settings.parking.name} 
                  onChange={(e) => updateSetting('parking', 'name', e.target.value)} 
                />
              </div>
              <div className="form-group">
                <label>Operating Hours</label>
                <input 
                  type="text" 
                  value={settings.parking.operatingHours} 
                  onChange={(e) => updateSetting('parking', 'operatingHours', e.target.value)} 
                />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                <div className="form-group">
                  <label>Hourly Rate (₱)</label>
                  <input 
                    type="number" 
                    value={settings.parking.hourlyRate} 
                    onChange={(e) => updateSetting('parking', 'hourlyRate', parseInt(e.target.value))} 
                  />
                </div>
                <div className="form-group">
                  <label>Max Duration (Hrs)</label>
                  <input 
                    type="number" 
                    value={settings.parking.maxDuration} 
                    onChange={(e) => updateSetting('parking', 'maxDuration', parseInt(e.target.value))} 
                  />
                </div>
              </div>
            </div>
          </section>

          {/* Booking Behavior */}
          <section className="settings-card glass">
            <h3><span>⚡</span> Booking Behavior</h3>
            <div className="settings-section">
              <div className="setting-row">
                <div className="setting-info">
                  <p className="setting-title">Enable New Bookings</p>
                  <p className="setting-desc">Allow users to reserve spots in real-time</p>
                </div>
                <label className="switch">
                  <input 
                    type="checkbox" 
                    checked={settings.behavior.enableBookings} 
                    onChange={(e) => updateSetting('behavior', 'enableBookings', e.target.checked)}
                  />
                  <span className="slider"></span>
                </label>
              </div>
              <div className="setting-row">
                <div className="setting-info">
                  <p className="setting-title">Allow Cancellations</p>
                  <p className="setting-desc">Let users cancel bookings via mobile app</p>
                </div>
                <label className="switch">
                  <input 
                    type="checkbox" 
                    checked={settings.behavior.allowCancellations} 
                    onChange={(e) => updateSetting('behavior', 'allowCancellations', e.target.checked)}
                  />
                  <span className="slider"></span>
                </label>
              </div>
              <div className="form-group">
                <label>Late Arrival Grace Period (Mins)</label>
                <input 
                  type="number" 
                  value={settings.behavior.gracePeriod} 
                  onChange={(e) => updateSetting('behavior', 'gracePeriod', parseInt(e.target.value))} 
                />
              </div>
            </div>
          </section>

          {/* Map Display */}
          <section className="settings-card glass">
            <h3><span>🗺️</span> Map Display Settings</h3>
            <div className="settings-section">
              <div className="setting-row">
                <div className="setting-info">
                  <p className="setting-title">Show Spot Labels</p>
                  <p className="setting-desc">Display 'A1', 'B2' etc on the map</p>
                </div>
                <label className="switch">
                  <input 
                    type="checkbox" 
                    checked={settings.display.showLabels} 
                    onChange={(e) => updateSetting('display', 'showLabels', e.target.checked)}
                  />
                  <span className="slider"></span>
                </label>
              </div>
              <div className="setting-row">
                <div className="setting-info">
                  <p className="setting-title">Show Prices on Map</p>
                  <p className="setting-desc">Display hourly rate markers</p>
                </div>
                <label className="switch">
                  <input 
                    type="checkbox" 
                    checked={settings.display.showPrices} 
                    onChange={(e) => updateSetting('display', 'showPrices', e.target.checked)}
                  />
                  <span className="slider"></span>
                </label>
              </div>
              <div className="form-group">
                <label>Default Map Zoom ({settings.display.defaultZoom})</label>
                <input 
                  type="range" 
                  min="10" max="20" step="1"
                  value={settings.display.defaultZoom} 
                  onChange={(e) => updateSetting('display', 'defaultZoom', parseInt(e.target.value))} 
                  style={{ accentColor: 'var(--primary)' }}
                />
              </div>
            </div>
          </section>

          {/* System & Security */}
          <section className="settings-card glass">
            <h3><span>⚙️</span> System & Security</h3>
            <div className="settings-section">
              <div className="form-group">
                <label>System Timezone</label>
                <select 
                  value={settings.system.timezone} 
                  onChange={(e) => updateSetting('system', 'timezone', e.target.value)}
                >
                  <option value="Asia/Manila">Asia/Manila (PST)</option>
                  <option value="UTC">Universal Coordinated Time (UTC)</option>
                </select>
              </div>
              <div className="form-group">
                 <button className="btn full-width" style={{ marginTop: '8px' }} onClick={() => alert('Change password feature is currently a stub.')}>
                   Change Admin Password
                 </button>
              </div>
              <div className="form-group">
                 <button className="btn btn-outline full-width" onClick={handleSignOut}>
                   Sign Out to Login
                 </button>
              </div>
            </div>
          </section>
        </div>

        <footer className="settings-footer">
          <p className="setting-desc">ParkAlisto v1.2.0 • Local Configuration Mode</p>
        </footer>
      </main>
    </div>
  )
}
