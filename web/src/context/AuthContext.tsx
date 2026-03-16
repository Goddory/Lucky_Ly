'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import axios from 'axios';

const AuthContext = createContext();

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api';

// Configure axios to include credentials (cookies) in every request
axios.defaults.withCredentials = true;

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    const checkAuth = async () => {
        try {
            const response = await axios.get(`${API_URL}/auth/me`);
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

export const useAuth = () => useContext(AuthContext);
