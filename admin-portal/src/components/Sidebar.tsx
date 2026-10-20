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
      <div className="sidebar-header">
        <div className="hotel-icon-badge">
          <UtensilsCrossed size={22} />
        </div>
        <div className="sidebar-brand">
          <h1>తెలుగు టిఫిన్ ఖాటా</h1>
          <p>Tiffin Debt Management</p>
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

        {isOwner && (
          <NavLink to="/migration" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <BookOpen size={18} />
            <span>Notebook Migration / పుస్తకం</span>
          </NavLink>
        )}

        {isAdmin && (
          <NavLink to="/reports" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <BarChart3 size={18} />
            <span>Reports / నివేదికలు</span>
          </NavLink>
        )}

        {isOwner && (
          <NavLink to="/users" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <UserCheck size={18} />
            <span>Family & Users / సభ్యులు</span>
          </NavLink>
        )}

        {isOwner && (
          <NavLink to="/audit" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <ShieldAlert size={18} />
            <span>Audit Trail / ఆడిట్ లాగ్</span>
          </NavLink>
        )}

        {isOwner && (
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
