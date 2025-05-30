# Facebook Replication Backend Server

This is the backend server for the Facebook replication app. It handles image uploads, storage, and deletion.

## Features

- Image upload with unique filenames
- Image storage in local filesystem
- Image metadata stored in SQLite database
- RESTful API endpoints for image operations
- CORS enabled for cross-origin requests
- File type validation (images only)

## Setup

1. Make sure you have Node.js installed (version 14 or higher recommended)

2. Install dependencies:
```bash
cd server
npm install
```

3. Create a `.env` file (optional, for custom configuration):
```
PORT=3000
```

## Running the Server

Development mode (with auto-reload):
```bash
npm run dev
```

Production mode:
```bash
npm start
```

The server will start on http://localhost:3000 by default.

## API Endpoints

### Upload Image
- **POST** `/upload`
- Content-Type: `multipart/form-data`
- Field name: `image`
- Returns: Image object with id, url, and upload timestamp

### Get All Images
- **GET** `/images`
- Returns: Array of image objects

### Delete Image
- **DELETE** `/images/:imageId`
- Returns: Success message or error

## Database

The server uses SQLite to store image metadata. The database file (`images.db`) will be created automatically when the server starts.

## File Storage

Uploaded images are stored in the `uploads` directory, which is created automatically when the server starts. Each image is given a unique filename using UUID. 