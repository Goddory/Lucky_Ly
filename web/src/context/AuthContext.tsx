'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import axios from 'axios';

interface User {
    user_id: string;
    username: string;
    email: string;
    fullName: string;
    avatar_url?: string;
    role: 'USER' | 'ADMIN';
}

interface AuthContextType {
    user: User | null;
    loading: boolean;
    login: (identifier: string, password: string) => Promise<any>;
    register: (userData: any) => Promise<any>;
    logout: (refreshToken?: string) => Promise<void>;
    checkAuth: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api';

// Configure axios to include credentials (cookies) in every request
axios.defaults.withCredentials = true;

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    const checkAuth = async () => {
        try {
            const response = await axios.get(`${API_URL}/auth/me`);
            // role is expected to be in response.data.user
            setUser(response.data.user);
        } catch (error) {
            setUser(null);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        checkAuth();
    }, []);

    const login = async (identifier, password) => {
        const response = await axios.post(`${API_URL}/auth/login`, { identifier, password });
        setUser(response.data.user);
        return response.data;
    };

    const register = async (userData) => {
        const response = await axios.post(`${API_URL}/auth/register`, userData);
        return response.data;
    };

    const logout = async (refreshToken) => {
        await axios.post(`${API_URL}/auth/logout`, { refreshToken });
        setUser(null);
    };

    return (
        <AuthContext.Provider value={{ user, loading, login, register, logout, checkAuth }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};
