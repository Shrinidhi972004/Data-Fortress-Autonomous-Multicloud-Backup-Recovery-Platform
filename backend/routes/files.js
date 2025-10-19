const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const File = require('../models/File');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = process.env.UPLOAD_DIR || './uploads';
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Generate unique filename with timestamp
    const timestamp = Date.now();
    const ext = path.extname(file.originalname);
    const name = path.basename(file.originalname, ext);
    const filename = `${timestamp}-${name}${ext}`;
    cb(null, filename);
  }
});

// File filter
const fileFilter = (req, file, cb) => {
  // Allow common file types - be more permissive for testing
  const allowedTypes = /jpeg|jpg|png|gif|pdf|doc|docx|txt|csv|xlsx|xls|zip|json|xml|log/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  
  // Also check mimetype but be more flexible
  const allowedMimeTypes = [
    'text/plain',
    'text/csv', 
    'application/json',
    'application/pdf',
    'application/zip',
    'image/jpeg',
    'image/png',
    'image/gif',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ];
  
  const mimetypeAllowed = allowedMimeTypes.includes(file.mimetype) || file.mimetype.startsWith('text/');

  if (extname || mimetypeAllowed) {
    return cb(null, true);
  } else {
    cb(new Error(`Invalid file type: ${file.mimetype}. Please upload a valid file.`));
  }
};

const upload = multer({
  storage: storage,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10 * 1024 * 1024 // 10MB default
  },
  fileFilter: fileFilter
});

// GET /api/files - List all files
router.get('/', async (req, res) => {
  try {
    const { user, limit = 50, page = 1, sortBy = 'createdAt', sortOrder = 'desc' } = req.query;
    
    const skip = (page - 1) * limit;
    const sort = { [sortBy]: sortOrder === 'desc' ? -1 : 1 };
    
    let query = {};
    if (user) {
      query.uploadedBy = user;
    }

    const files = await File.find(query)
      .sort(sort)
      .skip(skip)
      .limit(parseInt(limit))
      .select('-path'); // Don't expose file system path

    const total = await File.countDocuments(query);

    res.json({
      files,
      pagination: {
        current: parseInt(page),
        total: Math.ceil(total / limit),
        count: files.length,
        totalFiles: total
      }
    });
  } catch (error) {
    console.error('Error fetching files:', error);
    res.status(500).json({ error: 'Failed to fetch files' });
  }
});

// POST /api/files/upload - Upload a file
router.post('/upload', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const { uploadedBy = 'anonymous', description = '', tags = '' } = req.body;
    
    const fileData = new File({
      filename: req.file.filename,
      originalName: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size,
      path: req.file.path,
      uploadedBy,
      description,
      tags: tags ? tags.split(',').map(tag => tag.trim()) : []
    });

    await fileData.save();

    // Return file data without system path
    const responseData = fileData.toObject();
    delete responseData.path;

    res.status(201).json({
      message: 'File uploaded successfully',
      file: responseData
    });
  } catch (error) {
    console.error('Error uploading file:', error);
    
    // Clean up uploaded file if database save failed
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    
    res.status(500).json({ error: 'Failed to upload file' });
  }
});

// GET /api/files/:id - Get file metadata
router.get('/:id', async (req, res) => {
  try {
    const file = await File.findById(req.params.id).select('-path');
    
    if (!file) {
      return res.status(404).json({ error: 'File not found' });
    }

    res.json(file);
  } catch (error) {
    console.error('Error fetching file:', error);
    res.status(500).json({ error: 'Failed to fetch file' });
  }
});

// GET /api/files/:id/download - Download a file
router.get('/:id/download', async (req, res) => {
  try {
    const file = await File.findById(req.params.id);
    
    if (!file) {
      return res.status(404).json({ error: 'File not found' });
    }

    // Check if file exists on disk
    if (!fs.existsSync(file.path)) {
      return res.status(404).json({ error: 'File not found on disk' });
    }

    // Increment download count
    await file.incrementDownload();

    // Send file
    res.download(file.path, file.originalName, (err) => {
      if (err) {
        console.error('Error downloading file:', err);
        res.status(500).json({ error: 'Failed to download file' });
      }
    });
  } catch (error) {
    console.error('Error downloading file:', error);
    res.status(500).json({ error: 'Failed to download file' });
  }
});

// PUT /api/files/:id - Update file metadata
router.put('/:id', async (req, res) => {
  try {
    const { description, tags, uploadedBy } = req.body;
    
    const updateData = {};
    if (description !== undefined) updateData.description = description;
    if (uploadedBy !== undefined) updateData.uploadedBy = uploadedBy;
    if (tags !== undefined) {
      updateData.tags = Array.isArray(tags) ? tags : tags.split(',').map(tag => tag.trim());
    }

    const file = await File.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    ).select('-path');

    if (!file) {
      return res.status(404).json({ error: 'File not found' });
    }

    res.json({
      message: 'File updated successfully',
      file
    });
  } catch (error) {
    console.error('Error updating file:', error);
    res.status(500).json({ error: 'Failed to update file' });
  }
});

// DELETE /api/files/:id - Delete a file
router.delete('/:id', async (req, res) => {
  try {
    const file = await File.findById(req.params.id);
    
    if (!file) {
      return res.status(404).json({ error: 'File not found' });
    }

    // Delete file from disk
    if (fs.existsSync(file.path)) {
      fs.unlinkSync(file.path);
    }

    // Delete from database
    await File.findByIdAndDelete(req.params.id);

    res.json({ message: 'File deleted successfully' });
  } catch (error) {
    console.error('Error deleting file:', error);
    res.status(500).json({ error: 'Failed to delete file' });
  }
});

// GET /api/files/stats/summary - Get file statistics
router.get('/stats/summary', async (req, res) => {
  try {
    const totalFiles = await File.countDocuments();
    const totalSize = await File.aggregate([
      { $group: { _id: null, totalSize: { $sum: '$size' } } }
    ]);
    
    const fileTypes = await File.aggregate([
      { $group: { _id: '$mimetype', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);

    const recentFiles = await File.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .select('originalName createdAt size mimetype');

    res.json({
      totalFiles,
      totalSize: totalSize[0]?.totalSize || 0,
      fileTypes,
      recentFiles
    });
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
});

module.exports = router;
