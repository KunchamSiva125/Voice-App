import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { User, Role } from '../api/client';

interface ProtectedRouteProps {
  user: User | null;
  allowedRoles?: Role[];
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ user, allowedRoles }) => {
  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (allowedRoles && !allowedRoles.includes(user.role)) {
    return (
      <div style={{ padding: '40px', textAlign: 'center' }}>
        <h2 style={{ color: '#e11d48', marginBottom: '8px' }}>Access Denied / ప్రవేశం నిరాకరించబడింది</h2>
        <p style={{ color: '#64748b' }}>Your role ({user.role}) does not have permission to access this screen.</p>
      </div>
    );
  }

  return <Outlet />;
};
