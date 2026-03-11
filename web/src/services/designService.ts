import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api';

// Configure axios to include credentials (cookies)
axios.defaults.withCredentials = true;

export const saveDesign = async (designData) => {
    try {
        const response = await axios.post(`${API_URL}/designs`, designData);
        return response.data;
    } catch (error) {
        throw error.response?.data || error;
    }
};

export const getMyDesigns = async () => {
    try {
        const response = await axios.get(`${API_URL}/designs`);
        return response.data;
    } catch (error) {
        throw error.response?.data || error;
    }
};

export const getDesign = async (id) => {
    try {
        const response = await axios.get(`${API_URL}/designs/${id}`);
        return response.data;
    } catch (error) {
        throw error.response?.data || error;
    }
};

export const deleteDesign = async (id) => {
    try {
        const response = await axios.delete(`${API_URL}/designs/${id}`);
        return response.data;
    } catch (error) {
        throw error.response?.data || error;
    }
};
