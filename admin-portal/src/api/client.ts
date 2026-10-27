import axios from 'axios';

export const getApiBaseUrl = (): string => {
  const custom = localStorage.getItem('admin_custom_api_url');
  if (custom && custom.trim()) {
    return custom.trim();
  }
  if (import.meta.env.VITE_API_URL && import.meta.env.VITE_API_URL.startsWith('http')) {
    return import.meta.env.VITE_API_URL;
  }
  return 'https://voice-app-0cys.onrender.com/api';
};

export const apiClient = axios.create({
  baseURL: getApiBaseUrl(),
  timeout: 8000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor to inject JWT Bearer Token and dynamic baseURL
apiClient.interceptors.request.use((config) => {
  config.baseURL = getApiBaseUrl();
  const token = localStorage.getItem('tiffin_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Interceptor for 401 Unauthorized handling
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      localStorage.removeItem('tiffin_token');
      localStorage.removeItem('tiffin_user');
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// Helper to generate UUID v4 for idempotency
export function generateUUID(): string {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

// Types
export type Role = 'OWNER' | 'ADMIN' | 'FAMILY_MEMBER';
export type TransactionType = 'CREDIT' | 'PAYMENT' | 'DISCOUNT' | 'OPENING_BALANCE' | 'REVERSAL' | 'ADJUSTMENT';

export interface User {
  id: string;
  name: string;
  username: string;
  role: Role;
  active: boolean;
}

export interface Customer {
  id: string;
  name: string;
  normalizedName: string;
  aliases: string[];
  phoneNumber?: string;
  notes?: string;
  status: 'ACTIVE' | 'ARCHIVED';
  outstandingBalancePaise: number;
  balanceInRupees: number;
  createdAt: string;
  updatedAt: string;
}

export interface CustomerBalance {
  customerId: string;
  customerName: string;
  phoneNumber?: string;
  outstandingBalancePaise: number;
  balanceInRupees: number;
  totalCreditsPaise: number;
  totalPaymentsPaise: number;
  totalDiscountsPaise: number;
  latestTransactionAt?: string;
  teluguSpeechMessage: string;
}

export interface LedgerTransaction {
  id: string;
  customerId: string;
  customerName: string;
  type: TransactionType;
  amountPaise: number;
  amountInRupees: number;
  balanceEffectPaise: number;
  status: 'POSTED' | 'REVERSED';
  effectiveAt: string;
  createdAt: string;
  createdBy: string;
  description?: string;
  correctionReason?: string;
  reversesTransactionId?: string;
  reversalTransactionId?: string;
  hasReversal: boolean;
  metadata?: Record<string, any>;
}

export interface DailyReport {
  businessDate: string;
  totalCreditsRecordedPaise: number;
  totalCreditsInRupees: number;
  totalPaymentsCollectedPaise: number;
  totalPaymentsInRupees: number;
  totalDiscountsPaise: number;
  totalDiscountsInRupees: number;
  netChangePaise: number;
  netChangeInRupees: number;
  totalOutstandingDebtPaise: number;
  totalOutstandingDebtInRupees: number;
  activeCustomersCount: number;
  transactionsCountToday: number;
  teluguSummary: string;
}

export interface TopDebtor {
  customerId: string;
  customerName: string;
  phoneNumber?: string;
  balancePaise: number;
  balanceInRupees: number;
}

export interface OutstandingReport {
  totalOutstandingDebtPaise: number;
  totalOutstandingDebtInRupees: number;
  totalDebtorsCount: number;
  topDebtors: TopDebtor[];
}

export interface AuditEvent {
  id: string;
  actorUserId: string;
  actorUsername: string;
  action: string;
  entityType: string;
  entityId: string;
  occurredAt: string;
  reason: string;
  beforeSnapshot?: Record<string, any>;
  afterSnapshot?: Record<string, any>;
  clientIp?: string;
}

// API Service Call Methods
export const api = {
  // Auth
  login: async (username: string, password: string) => {
    const res = await apiClient.post('/auth/login', { username, password });
    return res.data;
  },
  getMe: async (): Promise<User> => {
    const res = await apiClient.get('/auth/me', { timeout: 3500 });
    return res.data;
  },

  // Customers
  getCustomers: async (search?: string, status?: string, page = 0, size = 20) => {
    const res = await apiClient.get('/customers', { params: { search, status, page, size } });
    return res.data;
  },
  getCustomer: async (id: string): Promise<Customer> => {
    const res = await apiClient.get(`/customers/${id}`);
    return res.data;
  },
  createCustomer: async (data: { name: string; phoneNumber?: string; aliases?: string[]; notes?: string; initialOpeningBalancePaise?: number }) => {
    const res = await apiClient.post('/customers', data);
    return res.data;
  },
  updateCustomer: async (id: string, data: Partial<Customer>) => {
    const res = await apiClient.patch(`/customers/${id}`, data);
    return res.data;
  },
  getCustomerBalance: async (id: string): Promise<CustomerBalance> => {
    const res = await apiClient.get(`/customers/${id}/balance`);
    return res.data;
  },
  getCustomerTransactions: async (id: string, page = 0, size = 20) => {
    const res = await apiClient.get(`/customers/${id}/transactions`, { params: { page, size } });
    return res.data;
  },
  archiveCustomer: async (id: string) => {
    const res = await apiClient.post(`/customers/${id}/archive`);
    return res.data;
  },
  deleteCustomer: async (id: string) => {
    const res = await apiClient.delete(`/customers/${id}`);
    return res.data;
  },
  mergeCustomers: async (sourceCustomerId: string, targetCustomerId: string, reason: string) => {
    const res = await apiClient.post('/customers/merge', { sourceCustomerId, targetCustomerId, reason });
    return res.data;
  },

  // Transactions
  recordCredit: async (customerId: string, amountPaise: number, description?: string) => {
    const res = await apiClient.post('/transactions/credit', { customerId, amountPaise, description }, {
      headers: { 'Idempotency-Key': generateUUID() }
    });
    return res.data;
  },
  recordPayment: async (customerId: string, amountPaise: number, allowExcessAsAdvance = false, description?: string) => {
    const res = await apiClient.post('/transactions/payment', { customerId, amountPaise, allowExcessAsAdvance, description }, {
      headers: { 'Idempotency-Key': generateUUID() }
    });
    return res.data;
  },
  applyDiscount: async (customerId: string, amountPaise: number, reason: string) => {
    const res = await apiClient.post('/transactions/discount', { customerId, amountPaise, reason }, {
      headers: { 'Idempotency-Key': generateUUID() }
    });
    return res.data;
  },
  importOpeningBalance: async (customerId: string, amountPaise: number, notebookPageNumber?: string, notes?: string, openingDate?: string) => {
    const res = await apiClient.post('/transactions/opening-balance', { customerId, amountPaise, notebookPageNumber, notes, openingDate }, {
      headers: { 'Idempotency-Key': generateUUID() }
    });
    return res.data;
  },
  reverseTransaction: async (id: string, reason: string) => {
    const res = await apiClient.post(`/transactions/${id}/reverse`, { reason });
    return res.data;
  },

  // Reports
  getDailyReport: async (date?: string): Promise<DailyReport> => {
    const res = await apiClient.get('/reports/daily', { params: { date } });
    return res.data;
  },
  getOutstandingReport: async (top = 10): Promise<OutstandingReport> => {
    const res = await apiClient.get('/reports/outstanding', { params: { top } });
    return res.data;
  },
  getTransactionsByRange: async (startDate?: string, endDate?: string, page = 0, size = 20) => {
    const res = await apiClient.get('/reports/transactions', { params: { startDate, endDate, page, size } });
    return res.data;
  },

  // Administration
  getUsers: async (): Promise<User[]> => {
    const res = await apiClient.get('/admin/users');
    return res.data;
  },
  createUser: async (user: { name: string; username: string; password: string; role: Role }) => {
    const res = await apiClient.post('/admin/users', user);
    return res.data;
  },
  toggleUserStatus: async (id: string, active: boolean) => {
    const res = await apiClient.patch(`/admin/users/${id}/status`, { active });
    return res.data;
  },
  getAuditEvents: async (page = 0, size = 25) => {
    const res = await apiClient.get('/admin/audit-events', { params: { page, size } });
    return res.data;
  },
  getExportCustomersUrl: () => `${getApiBaseUrl()}/admin/exports/customers.csv`,
  getExportTransactionsUrl: (startDate?: string, endDate?: string) => {
    let url = `${getApiBaseUrl()}/admin/exports/transactions.csv`;
    if (startDate && endDate) {
      url += `?startDate=${startDate}&endDate=${endDate}`;
    }
    return url;
  }
};
