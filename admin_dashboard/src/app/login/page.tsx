'use client'
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import './login.css';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    // For now, using a simple mock login or real Supabase auth if needed
    // The user asked for a "simple" login, so I'll keep it basic for now
    if (email === 'admin@usls.edu' && password === 'admin123') {
      localStorage.setItem('admin_auth', 'true');
      setTimeout(() => {
        router.push('/');
      }, 800);
    } else {
      setError('Invalid credentials. Please use admin@usls.edu / admin123');
      setIsLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-card glass fade-in-up">
        <div className="login-header">
          <div className="logo-icon">P</div>
          <h1>USLS Admin</h1>
          <p>Parking Command Center Access</p>
        </div>

        <form onSubmit={handleLogin} className="login-form">
          <div className="form-group">
            <label>Email Address</label>
            <input 
              type="email" 
              value={email} 
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@usls.edu"
              required
            />
          </div>
          
          <div className="form-group">
            <label>Password</label>
            <input 
              type="password" 
              value={password} 
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
            />
          </div>

          {error && <div className="login-error">{error}</div>}

          <button type="submit" className="login-button" disabled={isLoading}>
            {isLoading ? 'Authenticating...' : 'Sign In to Dashboard'}
          </button>
        </form>

        <div className="login-footer">
          <p>&copy; 2026 ParkAlisto USLS Division</p>
        </div>
      </div>
    </div>
  );
}
