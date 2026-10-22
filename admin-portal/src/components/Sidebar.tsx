import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  Receipt,
  RotateCcw,
  BookOpen,
  BarChart3,
  UserCheck,
  ShieldAlert,
  Download,
  LogOut,
  UtensilsCrossed
} from 'lucide-react';
import { User } from '../api/client';

interface SidebarProps {
  user: User | null;
  onLogout: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ user, onLogout }) => {
  const isOwner = user?.role === 'OWNER';
  const isAdmin = user?.role === 'ADMIN' || isOwner;

  return (
    <aside className="sidebar">
      <div className="sidebar-header" style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '16px 14px' }}>
        <img
          src="/logo.png"
          alt="Mahima Tiffin Centre Logo"
          style={{
            width: '44px',
            height: '44px',
            borderRadius: '50%',
            objectFit: 'cover',
            boxShadow: '0 2px 10px rgba(245, 158, 11, 0.45)',
            border: '2px solid #f59e0b',
            flexShrink: 0
          }}
        />
        <div className="sidebar-brand">
          <h1 style={{ fontSize: '15px', fontWeight: 800, color: '#f8fafc', margin: 0, lineHeight: 1.2 }}>Mahima Tiffin Centre</h1>
          <p style={{ fontSize: '11px', color: '#f59e0b', fontWeight: 600, margin: '2px 0 0 0' }}>మహిమ టిఫిన్ సెంటర్</p>
        </div>
      </div>

      <nav className="sidebar-nav">
        <NavLink to="/dashboard" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <LayoutDashboard size={18} />
          <span>Dashboard / వివరాలు</span>
        </NavLink>

        <NavLink to="/customers" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <Users size={18} />
          <span>Customers / ఖాతాదారులు</span>
        </NavLink>

        <NavLink to="/transactions" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <Receipt size={18} />
          <span>Transactions / లావాదేవీలు</span>
        </NavLink>

        {isAdmin && (
          <NavLink to="/corrections" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <RotateCcw size={18} />
            <span>Corrections / సరిదిద్దుట</span>
          </NavLink>
        )}

        {isAdmin && (
          <NavLink to="/migration" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <BookOpen size={18} />
            <span>Notebook Migration / పుస్తకం బాకీలు</span>
          </NavLink>
        )}

        {isAdmin && (
          <NavLink to="/reports" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <BarChart3 size={18} />
            <span>Reports / నివేదికలు</span>
          </NavLink>
        )}

        {isAdmin && (
          <NavLink to="/users" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <UserCheck size={18} />
            <span>Family & Users / సభ్యులు</span>
          </NavLink>
        )}

        {isAdmin && (
          <NavLink to="/audit" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <ShieldAlert size={18} />
            <span>Audit Trail / ఆడిట్ లాగ్</span>
          </NavLink>
        )}

        {isAdmin && (
          <NavLink to="/exports" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <Download size={18} />
            <span>CSV Exports / బ్యాకప్</span>
          </NavLink>
        )}
      </nav>

      <div className="sidebar-footer">
        <div className="user-badge">
          <div className="user-avatar">
            {user?.name ? user.name.charAt(0).toUpperCase() : 'U'}
          </div>
          <div className="user-meta">
            <h4>{user?.name || 'Cashier'}</h4>
            <span>{user?.role || 'STAFF'}</span>
          </div>
        </div>

        <button onClick={onLogout} className="logout-btn" title="Logout / లాగౌట్">
          <LogOut size={18} />
        </button>
      </div>
    </aside>
  );
};
