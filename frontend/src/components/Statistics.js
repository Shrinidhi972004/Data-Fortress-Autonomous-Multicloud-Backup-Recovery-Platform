import React from 'react';

const Statistics = ({ stats }) => {
  const formatFileSize = (bytes) => {
    if (!bytes || bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  if (!stats) {
    return null;
  }

  return (
    <section className="stats">
      <div className="stat-card">
        <div className="stat-value">{stats.totalFiles}</div>
        <div className="stat-label">Total Files</div>
      </div>
      
      <div className="stat-card">
        <div className="stat-value">{formatFileSize(stats.totalSize)}</div>
        <div className="stat-label">Total Size</div>
      </div>
      
      <div className="stat-card">
        <div className="stat-value">{stats.fileTypes?.length || 0}</div>
        <div className="stat-label">File Types</div>
      </div>
      
      <div className="stat-card">
        <div className="stat-value">{stats.recentFiles?.length || 0}</div>
        <div className="stat-label">Recent Files</div>
      </div>
    </section>
  );
};

export default Statistics;
