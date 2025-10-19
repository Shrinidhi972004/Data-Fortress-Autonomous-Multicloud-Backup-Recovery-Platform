import React from 'react';

const FileList = ({ files, loading, onRefresh, onDelete, onDownload }) => {
  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getFileIcon = (mimetype) => {
    if (mimetype.startsWith('image/')) return '🖼️';
    if (mimetype.includes('pdf')) return '📄';
    if (mimetype.includes('document') || mimetype.includes('word')) return '📝';
    if (mimetype.includes('spreadsheet') || mimetype.includes('excel')) return '📊';
    if (mimetype.includes('video')) return '🎥';
    if (mimetype.includes('audio')) return '🎵';
    if (mimetype.includes('zip') || mimetype.includes('archive')) return '📦';
    return '📁';
  };

  if (loading) {
    return (
      <section className="files-section">
        <div className="loading">Loading files...</div>
      </section>
    );
  }

  return (
    <section className="files-section">
      <div className="files-header">
        <h2>Uploaded Files ({files.length})</h2>
        <button onClick={onRefresh} className="refresh-btn">
          Refresh
        </button>
      </div>

      {files.length === 0 ? (
        <div className="loading">
          No files uploaded yet. Upload your first file above!
        </div>
      ) : (
        <div className="files-grid">
          {files.map((file) => (
            <div key={file._id} className="file-card">
              <div className="file-header">
                <div className="file-name">
                  {getFileIcon(file.mimetype)} {file.originalName}
                </div>
                <div className="file-size">
                  {formatFileSize(file.size)}
                </div>
              </div>

              <div className="file-info">
                <div><strong>Type:</strong> {file.mimetype}</div>
                <div><strong>Uploaded:</strong> {formatDate(file.createdAt)}</div>
                <div><strong>By:</strong> {file.uploadedBy}</div>
                {file.downloadCount > 0 && (
                  <div><strong>Downloads:</strong> {file.downloadCount}</div>
                )}
              </div>

              {file.description && (
                <div className="file-description">
                  "{file.description}"
                </div>
              )}

              {file.tags && file.tags.length > 0 && (
                <div className="file-tags">
                  {file.tags.map((tag, index) => (
                    <span key={index} className="tag">
                      {tag}
                    </span>
                  ))}
                </div>
              )}

              <div className="file-actions">
                <button
                  onClick={() => onDownload(file._id, file.originalName)}
                  className="btn-download"
                >
                  Download
                </button>
                <button
                  onClick={() => onDelete(file._id)}
                  className="btn-delete"
                >
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </section>
  );
};

export default FileList;
