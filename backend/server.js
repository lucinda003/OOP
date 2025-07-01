const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const multer = require("multer"); // NEW: For file uploads
const path = require("path");
const bodyParser = require("body-parser");
const fs = require('fs');

const app = express();
const SECRET_KEY = "your_secret_key"; // Change this for security

// Middleware
app.use(cors({ origin: "*", methods: ["GET", "POST", "PUT", "DELETE"] }));
app.use(bodyParser.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads'))); // Serve uploads folder

// Create uploads folder if not exists
if (!fs.existsSync('./uploads')){
    fs.mkdirSync('./uploads');
}

// Multer setup
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/'); // Save uploads to /uploads folder
  },
  filename: (req, file, cb) => {
    const uniqueName = Date.now() + '-' + file.originalname;
    cb(null, uniqueName);
  }
});
const upload = multer({ storage: storage });

// MySQL Database Connection
const pool = mysql.createPool({
  host: "localhost",
  user: "root",
  password: "",
  database: "hello",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Verify database connection
pool.getConnection((err, connection) => {
  if (err) {
    console.error("MySQL connection error:", err);
    process.exit(1);
  }
  console.log("MySQL connected successfully");

  connection.query(`
    CREATE TABLE IF NOT EXISTS users (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      email VARCHAR(255) NOT NULL UNIQUE,
      password VARCHAR(255) NOT NULL
    )
  `);

  // NOTE: If you already have the table, run this SQL in your database to add columns:
  // ALTER TABLE feed_images ADD COLUMN title VARCHAR(255) NOT NULL DEFAULT '', ADD COLUMN subtitle VARCHAR(255) NOT NULL DEFAULT '';
  connection.query(`
    CREATE TABLE IF NOT EXISTS feed_images (
      id INT AUTO_INCREMENT PRIMARY KEY,
      image_path VARCHAR(255) NOT NULL,
      title VARCHAR(255) NOT NULL DEFAULT '',
      subtitle VARCHAR(255) NOT NULL DEFAULT '',
      uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `, (err) => {
    connection.release();
    if (err) {
      console.error("Table creation error:", err);
    }
  });
});

// Test Route
app.get("/", (_, res) => {
  res.send("Backend is running! Try /users or /images endpoint");
});

// ---------------- USERS ROUTES ----------------

// Get All Users
app.get("/users", (_, res) => {
  pool.query("SELECT id, name, email FROM users", (err, results) => {
    if (err) {
      console.error("Database error:", err);
      return res.status(500).json({ error: "Database error" });
    }
    res.json(results);
  });
});

// Register User
app.post("/users", async (req, res) => {
  const { name, email, password } = req.body;
  if (!name || !email || !password) {
    return res.status(400).json({ error: "All fields are required" });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    pool.query(
      "INSERT INTO users (name, email, password) VALUES (?, ?, ?)",
      [name, email, hashedPassword],
      (err, results) => {
        if (err) {
          console.error("Insert error:", err);
          return res.status(500).json({ error: "Database error" });
        }
        res.status(201).json({ id: results.insertId, name, email });
      }
    );
  } catch (error) {
    console.error("Hashing error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Login User
app.post("/login", (req, res) => {
  const { email, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({ message: "Email and password are required" });
  }

  pool.query("SELECT * FROM users WHERE email = ?", [email], async (err, results) => {
    if (err) {
      console.error("Login error:", err);
      return res.status(500).json({ message: "Database error" });
    }

    if (results.length === 0) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const user = results[0];
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const token = jwt.sign(
      { id: user.id, name: user.name, email: user.email },
      SECRET_KEY,
      { expiresIn: "1h" }
    );

    res.json({ message: "Login successful", token });
  });
});

// Update User
app.put("/users/:id", (req, res) => {
  const { id } = req.params;
  const { name, email } = req.body;

  if (!name || !email) {
    return res.status(400).json({ error: "Name and email are required" });
  }

  pool.query(
    "UPDATE users SET name = ?, email = ? WHERE id = ?",
    [name, email, id],
    (err, results) => {
      if (err) {
        console.error("Update error:", err);
        return res.status(500).json({ error: "Database error" });
      }
      if (results.affectedRows === 0) {
        return res.status(404).json({ error: "User not found" });
      }
      res.json({ message: "User updated", id, name, email });
    }
  );
});

// Delete User
app.delete("/users/:id", (req, res) => {
  const { id } = req.params;
  pool.query("DELETE FROM users WHERE id = ?", [id], (err, results) => {
    if (err) {
      console.error("Delete error:", err);
      return res.status(500).json({ error: "Database error" });
    }
    if (results.affectedRows === 0) {
      return res.status(404).json({ error: "User not found" });
    }
    res.json({ message: "User deleted" });
  });
});

// ---------------- IMAGES ROUTES ----------------

// Upload Image to feed_images with title and subtitle
app.post("/upload", upload.single('image'), (req, res) => {
  console.log('Upload endpoint hit');
  if (!req.file) {
    console.log('No file received');
    return res.status(400).json({ error: "No image uploaded" });
  }

  const imagePath = req.file.filename;
  const title = req.body.title || '';
  const subtitle = req.body.subtitle || '';

  pool.query(
    "INSERT INTO feed_images (image_path, title, subtitle) VALUES (?, ?, ?)",
    [imagePath, title, subtitle],
    (err, results) => {
      if (err) {
        console.error("Image insert error:", err);
        return res.status(500).json({ error: "Database error" });
      }
      res.status(201).json({ 
        message: "Image uploaded", 
        image_path: imagePath,
        title,
        subtitle
      });
    }
  );
});

// Get All Uploaded Feed Images (with title and subtitle)
app.get("/images", (_, res) => {
  pool.query("SELECT id, image_path, title, subtitle, uploaded_at FROM feed_images ORDER BY uploaded_at DESC", (err, results) => {
    if (err) {
      console.error("Images fetch error:", err);
      return res.status(500).json({ error: "Database error" });
    }

    const images = results.map(img => ({
      id: img.id,
      url: `http://localhost:3000/uploads/${img.image_path}`,
      title: img.title,
      subtitle: img.subtitle,
      uploaded_at: img.uploaded_at
    }));

    res.json(images);
  });
});

// Delete image from feed_images
app.delete("/images/:id", (req, res) => {
  const { id } = req.params;

  // First, find the image file path from the database
  pool.query("SELECT image_path FROM feed_images WHERE id = ?", [id], (err, results) => {
    if (err) {
      console.error("Find image error:", err);
      return res.status(500).json({ error: "Database error" });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: "Image not found" });
    }

    const filePath = path.join(__dirname, "uploads", results[0].image_path);

    // Delete the image from the database
    pool.query("DELETE FROM feed_images WHERE id = ?", [id], (err, dbResult) => {
      if (err) {
        console.error("Delete image DB error:", err);
        return res.status(500).json({ error: "Database error" });
      }

      // Delete the physical file from the server
      fs.unlink(filePath, (fsErr) => {
        if (fsErr) {
          console.warn("File deletion warning (file may not exist):", fsErr);
        } else {
          console.log("File deleted:", filePath);
        }

        res.json({ message: "Image deleted successfully" });
      });
    });
  });
});


// Start Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
