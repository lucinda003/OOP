const express = require('express');
const multer = require('multer');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const sqlite3 = require('sqlite3').verbose();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}

// Configure multer for image upload
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/');
  },
  filename: function (req, file, cb) {
    const uniqueId = uuidv4();
    const ext = path.extname(file.originalname);
    cb(null, uniqueId + ext);
  }
});

const upload = multer({ 
  storage: storage,
  fileFilter: (req, file, cb) => {
    // Accept images only
    if (!file.originalname.match(/\.(jpg|jpeg|png|gif)$/)) {
      return cb(new Error('Only image files are allowed!'), false);
    }
    cb(null, true);
  }
});

// Initialize SQLite database
const db = new sqlite3.Database('images.db', (err) => {
  if (err) {
    console.error('Error opening database:', err);
  } else {
    console.log('Connected to SQLite database');
    // Create images table if it doesn't exist
    db.run(`CREATE TABLE IF NOT EXISTS images (
      id TEXT PRIMARY KEY,
      filename TEXT NOT NULL,
      url TEXT NOT NULL,
      uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Create users table if it doesn't exist
    db.run(`CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);
  }
});

// Upload endpoint
app.post('/upload', upload.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No image file provided' });
  }

  const imageId = path.parse(req.file.filename).name; // Get UUID without extension
  const imageUrl = `http://localhost:${port}/uploads/${req.file.filename}`;

  db.run(
    'INSERT INTO images (id, filename, url) VALUES (?, ?, ?)',
    [imageId, req.file.filename, imageUrl],
    function(err) {
      if (err) {
        console.error('Error saving image to database:', err);
        // Delete the uploaded file if database insert fails
        fs.unlinkSync(req.file.path);
        return res.status(500).json({ error: 'Failed to save image information' });
      }
      res.json({
        id: imageId,
        url: imageUrl,
        uploaded_at: new Date().toISOString()
      });
    }
  );
});

// Get all images endpoint
app.get('/images', (req, res) => {
  db.all('SELECT * FROM images ORDER BY uploaded_at DESC', [], (err, rows) => {
    if (err) {
      console.error('Error fetching images:', err);
      return res.status(500).json({ error: 'Failed to fetch images' });
    }
    res.json(rows);
  });
});

// Delete image endpoint
app.delete('/images/:imageId', (req, res) => {
  const imageId = req.params.imageId;
  console.log(`Attempting to delete image with ID: ${imageId}`);

  // Try to delete by UUID (string) first
  db.get('SELECT filename FROM images WHERE id = ?', [imageId], (err, row) => {
    if (err) {
      console.error('Database error when fetching image by UUID:', err);
      return res.status(500).json({ 
        error: 'Failed to fetch image information (UUID check)',
        details: err.message 
      });
    }

    if (row) {
      console.log(`Found image by UUID: ${imageId}`);
    const filePath = path.join(uploadsDir, row.filename);

    // Delete the file from the filesystem
    fs.unlink(filePath, (err) => {
      if (err) {
          console.error('Error deleting file from disk (UUID delete):', err);
          return res.status(500).json({ 
            error: 'Failed to delete image file',
            details: err.message
          });
      }

        console.log(`Successfully deleted file from disk: ${filePath}`);

      // Delete the database record
      db.run('DELETE FROM images WHERE id = ?', [imageId], function(err) {
        if (err) {
            console.error('Error deleting image from database (UUID delete):', err);
            return res.status(500).json({ 
              error: 'Failed to delete image record',
              details: err.message
            });
          }
          console.log(`Successfully deleted image record for ID: ${imageId}`);
          res.status(200).json({ 
            message: 'Image deleted successfully',
            imageId: imageId
          });
        });
      });
    } else {
      // If not found by UUID, try to delete by numerical ID
      const numericalId = parseInt(imageId, 10);
      if (!isNaN(numericalId)) {
        db.get('SELECT filename FROM images WHERE id = ?', [numericalId], (err, row) => {
          if (err) {
            console.error('Database error when fetching image by numerical ID:', err);
            return res.status(500).json({ 
              error: 'Failed to fetch image information (numerical ID check)',
              details: err.message 
            });
          }

          if (row) {
            console.log(`Found image by numerical ID: ${numericalId}`);
            const filePath = path.join(uploadsDir, row.filename);

            // Delete the file from the filesystem
            fs.unlink(filePath, (err) => {
              if (err) {
                console.error('Error deleting file from disk (numerical ID delete):', err);
                return res.status(500).json({ 
                  error: 'Failed to delete image file',
                  details: err.message
                });
        }

              console.log(`Successfully deleted file from disk: ${filePath}`);

              // Delete the database record
              db.run('DELETE FROM images WHERE id = ?', [numericalId], function(err) {
                if (err) {
                  console.error('Error deleting image from database (numerical ID delete):', err);
                  return res.status(500).json({ 
                    error: 'Failed to delete image record',
                    details: err.message
                  });
                }
                console.log(`Successfully deleted image record for ID: ${numericalId}`);
                res.status(200).json({ 
                  message: 'Image deleted successfully',
                  imageId: numericalId
                });
      });
    });
          } else {
            // Not found by either UUID or numerical ID
            console.log(`Image not found with ID: ${imageId}`);
            return res.status(404).json({ 
              error: 'Image not found',
              message: `No image found with ID: ${imageId}`
            });
          }
        });
      } else {
        // Provided imageId is not a valid number or UUID format
        console.log(`Invalid image ID format: ${imageId}`);
         return res.status(400).json({ 
          error: 'Invalid ID format',
          message: 'Provided image ID is not a valid number or UUID'
         });
      }
    }
  });
});

// Add a debug endpoint to check image existence
app.get('/images/:imageId', (req, res) => {
  const imageId = req.params.imageId;
  console.log(`Checking existence of image: ${imageId}`);
  
  db.get('SELECT * FROM images WHERE id = ?', [imageId], (err, row) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Database error', details: err.message });
    }
    
    if (!row) {
      return res.status(404).json({ 
        error: 'Image not found',
        message: `No image found with ID: ${imageId}`
      });
    }
    
    res.json(row);
  });
});

// Debug endpoint to list all image IDs
app.get('/debug/images', (req, res) => {
  db.all('SELECT id, filename, url FROM images', [], (err, rows) => {
    if (err) {
      console.error('Error fetching images:', err);
      return res.status(500).json({ error: 'Failed to fetch images' });
    }
    res.json(rows);
  });
});

// Create user endpoint
app.post('/users', async (req, res) => {
  const { name, email, password } = req.body;
  
  console.log('Attempting to create user:', { name, email });

  if (!name || !email || !password) {
    return res.status(400).json({ 
      error: 'Missing required fields',
      message: 'Name, email, and password are required' 
    });
  }

  try {
    // Check if user already exists
    db.get('SELECT id FROM users WHERE email = ?', [email], (err, row) => {
      if (err) {
        console.error('Database error checking existing user:', err);
        return res.status(500).json({ 
          error: 'Database error',
          message: 'Failed to check existing user' 
        });
      }

      if (row) {
        return res.status(409).json({ 
          error: 'User exists',
          message: 'A user with this email already exists' 
        });
      }

      // Create new user
      db.run(
        'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
        [name, email, password], // Note: In production, password should be hashed
        function(err) {
          if (err) {
            console.error('Error creating user:', err);
            return res.status(500).json({ 
              error: 'Database error',
              message: 'Failed to create user' 
            });
          }
          
          console.log('User created successfully with ID:', this.lastID);
          res.status(201).json({ 
            message: 'User created successfully',
            userId: this.lastID 
          });
        }
      );
    });
  } catch (e) {
    console.error('Error in create user endpoint:', e);
    res.status(500).json({ 
      error: 'Server error',
      message: 'An unexpected error occurred' 
    });
  }
});

// Login endpoint
app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  
  console.log('Login attempt for email:', email);

  if (!email || !password) {
    return res.status(400).json({ 
      error: 'Missing credentials',
      message: 'Email and password are required' 
    });
  }

  try {
    db.get(
      'SELECT id, name, email FROM users WHERE email = ? AND password = ?',
      [email, password], // Note: In production, use proper password hashing
      (err, row) => {
        if (err) {
          console.error('Database error during login:', err);
          return res.status(500).json({ 
            error: 'Database error',
            message: 'Failed to authenticate user' 
          });
        }

        if (!row) {
          return res.status(401).json({ 
            error: 'Invalid credentials',
            message: 'Invalid email or password' 
          });
        }

        // In a real app, you would generate a proper JWT token here
        const token = 'dummy-token-' + Date.now();
        
        res.json({
          message: 'Login successful',
          token: token,
          user: {
            id: row.id,
            name: row.name,
            email: row.email
          }
        });
      }
    );
  } catch (e) {
    console.error('Error in login endpoint:', e);
    res.status(500).json({ 
      error: 'Server error',
      message: 'An unexpected error occurred' 
    });
  }
});

// Get all users endpoint
app.get('/users', (req, res) => {
  db.all('SELECT id, name, email, created_at FROM users', [], (err, rows) => {
    if (err) {
      console.error('Error fetching users:', err);
      return res.status(500).json({ 
        error: 'Database error',
        message: 'Failed to fetch users' 
      });
    }
    res.json(rows);
  });
});

// Start the server
app.listen(port, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${port}`);
  console.log('You can access it via:');
  console.log(`- Local: http://localhost:${port}`);
  console.log(`- Network: http://<your-ip-address>:${port}`);
}); 