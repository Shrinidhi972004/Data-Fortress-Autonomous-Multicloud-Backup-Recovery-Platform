import React, { useState, useEffect } from 'react';
import axios from 'axios';
import FileUpload from './components/FileUpload';
import FileList from './components/FileList';
import Statistics from './components/Statistics';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000';

function App() {
  const [files, setFiles] = useState([]);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const fetchFiles = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_BASE_URL}/api/files`);
      setFiles(response.data.files);
      setError('');
    } catch (err) {
      setError('Failed to fetch files');
      console.error('Error fetching files:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchStats = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/files/stats/summary`);
      setStats(response.data);
    } catch (err) {
      console.error('Error fetching stats:', err);
    }
  };

  useEffect(() => {
    fetchFiles();
    fetchStats();
  }, []);

  const handleFileUpload = async (formData) => {
    try {
      const response = await axios.post(`${API_BASE_URL}/api/files/upload`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });
      
      setSuccess('File uploaded successfully!');
      setError('');
      
      // Refresh files and stats
      await fetchFiles();
      await fetchStats();
      
      // Clear success message after 3 seconds
      setTimeout(() => setSuccess(''), 3000);
      
      return response.data;
    } catch (err) {
      const errorMessage = err.response?.data?.error || 'Failed to upload file';
      setError(errorMessage);
      setSuccess('');
      throw new Error(errorMessage);
    }
  };

  const handleFileDelete = async (fileId) => {
    if (!window.confirm('Are you sure you want to delete this file?')) {
      return;
    }

    try {
      await axios.delete(`${API_BASE_URL}/api/files/${fileId}`);
      setSuccess('File deleted successfully!');
      setError('');
      
      // Refresh files and stats
      await fetchFiles();
      await fetchStats();
      
      // Clear success message after 3 seconds
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      const errorMessage = err.response?.data?.error || 'Failed to delete file';
      setError(errorMessage);
      setSuccess('');
    }
  };

  const handleFileDownload = async (fileId, filename) => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/files/${fileId}/download`, {
        responseType: 'blob'
      });
      
      // Create download link
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', filename);
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);
      
      setSuccess('File download started!');
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      const errorMessage = err.response?.data?.error || 'Failed to download file';
      setError(errorMessage);
    }
  };

  return (
    <div className="container">
      <header className="header">
        <h1>File Upload Application</h1>
        <p>Data Fortress Test Workload - Upload, manage, and download files</p>
      </header>

      {error && <div className="error">{error}</div>}
      {success && <div className="success">{success}</div>}

      <Statistics stats={stats} />

      <FileUpload onUpload={handleFileUpload} />

      <FileList 
        files={files}
        loading={loading}
        onRefresh={fetchFiles}
        onDelete={handleFileDelete}
        onDownload={handleFileDownload}
      />
    </div>
  );
}

export default App;
