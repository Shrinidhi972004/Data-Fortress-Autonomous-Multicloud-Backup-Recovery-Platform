import React, { useState } from 'react';

const FileUpload = ({ onUpload }) => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [uploadedBy, setUploadedBy] = useState('');
  const [description, setDescription] = useState('');
  const [tags, setTags] = useState('');
  const [uploading, setUploading] = useState(false);
  const [dragOver, setDragOver] = useState(false);

  const handleFileSelect = (file) => {
    setSelectedFile(file);
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    setDragOver(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    setDragOver(false);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setDragOver(false);
    
    const files = e.dataTransfer.files;
    if (files.length > 0) {
      handleFileSelect(files[0]);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!selectedFile) {
      alert('Please select a file');
      return;
    }

    setUploading(true);

    try {
      const formData = new FormData();
      formData.append('file', selectedFile);
      formData.append('uploadedBy', uploadedBy || 'anonymous');
      formData.append('description', description);
      formData.append('tags', tags);

      await onUpload(formData);
      
      // Reset form
      setSelectedFile(null);
      setUploadedBy('');
      setDescription('');
      setTags('');
      
      // Reset file input
      const fileInput = document.getElementById('file-input');
      if (fileInput) {
        fileInput.value = '';
      }
      
    } catch (error) {
      console.error('Upload failed:', error);
    } finally {
      setUploading(false);
    }
  };

  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  return (
    <section className="upload-section">
      <h2>Upload File</h2>
      <form onSubmit={handleSubmit} className="upload-form">
        <div className="form-group">
          <label htmlFor="file-input">Select File</label>
          <div className="file-input">
            <input
              type="file"
              id="file-input"
              onChange={(e) => handleFileSelect(e.target.files[0])}
              required
            />
            <label
              htmlFor="file-input"
              className={`file-input-label ${dragOver ? 'dragover' : ''}`}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
            >
              {selectedFile ? (
                <div>
                  <strong>Selected:</strong> {selectedFile.name}
                  <br />
                  <small>Size: {formatFileSize(selectedFile.size)}</small>
                </div>
              ) : (
                <div>
                  <strong>Click to select a file</strong> or drag and drop
                  <br />
                  <small>Supported: Images, Documents, Videos, Archives (max 10MB)</small>
                </div>
              )}
            </label>
          </div>
        </div>

        <div className="form-group">
          <label htmlFor="uploadedBy">Uploaded By (optional)</label>
          <input
            type="text"
            id="uploadedBy"
            value={uploadedBy}
            onChange={(e) => setUploadedBy(e.target.value)}
            placeholder="Enter your name"
          />
        </div>

        <div className="form-group">
          <label htmlFor="description">Description (optional)</label>
          <textarea
            id="description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Enter file description"
            rows="3"
          />
        </div>

        <div className="form-group">
          <label htmlFor="tags">Tags (optional)</label>
          <input
            type="text"
            id="tags"
            value={tags}
            onChange={(e) => setTags(e.target.value)}
            placeholder="Enter tags separated by commas"
          />
        </div>

        <button
          type="submit"
          className="upload-btn"
          disabled={uploading || !selectedFile}
        >
          {uploading ? 'Uploading...' : 'Upload File'}
        </button>
      </form>
    </section>
  );
};

export default FileUpload;
