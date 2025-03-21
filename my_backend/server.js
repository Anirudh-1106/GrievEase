const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Add test route
app.get('/', (req, res) => {
  res.json({ message: 'Server is running' });
});

// Add error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

// Updated connection string with database name
const connectionString = 'mongodb+srv://anirudhmnair2005:mysticace@cluster0.za78g.mongodb.net/GrievanceDB?retryWrites=true&w=majority';

mongoose.connect(connectionString, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => {
    console.log('Successfully connected to MongoDB.');
  })
  .catch((error) => {
    console.error('Error connecting to MongoDB:', error);
  });

// Create User Schema with required fields
const userSchema = new mongoose.Schema({
  name: { 
    type: String, 
    required: true 
  },
  registrationNumber: { 
    type: String, 
    required: true,
    unique: true 
  },
  email: {
    type: String,
    required: true,
    unique: true,
    validate: {
      validator: function(v) {
        return v.endsWith('@mbcet.ac.in');
      },
      message: 'Email must be a valid MBCET email address'
    }
  },
  password: { 
    type: String, 
    required: true 
  }
}, { timestamps: true });

const User = mongoose.model('User', userSchema);

const complaintSchema = new mongoose.Schema({
  complaintId: {
    type: String,
    unique: true,
    required: true
  },
  category: {
    type: String,
    required: true,
    enum: ['Infrastructure', 'Academics', 'Administration', 'Hostel', 'Others']
  },
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['Pending', 'In Progress', 'Resolved', 'Reopened'],
    default: 'Pending'
  },
  userName: {
    type: String,
    required: true
  },
  timeline: [{
    status: String,
    timestamp: {
      type: Date,
      default: Date.now
    },
    comment: String
  }],
  image: {
    type: String,
    required: false
  }
}, { timestamps: true });

const Complaint = mongoose.model('Complaint', complaintSchema);

// Generate unique complaint ID
const generateComplaintId = async () => {
  try {
    const lastComplaint = await Complaint.findOne({}, { complaintId: 1 })
      .sort({ complaintId: -1 });
    
    if (!lastComplaint) {
      return 'C00001';
    }

    const lastNumber = parseInt(lastComplaint.complaintId.replace('C', ''));
    const newNumber = lastNumber + 1;
    return `C${newNumber.toString().padStart(5, '0')}`;
  } catch (error) {
    console.error('Error generating complaint ID:', error);
    throw error;
  }
};

app.post('/signup', async (req, res) => {
  console.log('Received signup request with body:', req.body);
  if (!req.body.email || !req.body.password || !req.body.name || !req.body.registrationNumber) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  try {
    // Check if user already exists
    const existingUser = await User.findOne({ 
      $or: [  
        { email: req.body.email },
        { registrationNumber: req.body.registrationNumber }
      ]
    });

    if (existingUser) {
      console.log('User already exists:', existingUser.email);
      return res.status(400).json({ 
        message: 'User with this email or registration number already exists' 
      });
    }

    // Create new user
    const user = new User({
      name: req.body.name,
      registrationNumber: req.body.registrationNumber,
      email: req.body.email,
      password: req.body.password // In production, hash this password
    });

    await user.save();
    console.log('User created successfully:', user.email);
    
    res.status(201).json({ 
      success: true,
      message: 'User registered successfully'
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(400).json({ 
      success: false,
      message: error.message 
    });
  }
});

app.post('/login', async (req, res) => {
  console.log('Received login request with email:', req.body.email);
  if (!req.body.email || !req.body.password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  try {
    const user = await User.findOne({
      email: req.body.email,
      password: req.body.password // In production, compare hashed passwords
    });

    if (user) {
      console.log('Login successful for:', user.email);
      res.json({ 
        success: true, 
        name: user.name, // Here's where the name is sent in the login response
        userId: user._id // Include userId in the response
      });
    } else {
      console.log('Login failed: Invalid credentials');
      res.status(401).json({ 
        success: false, 
        message: 'Invalid email or password' 
      });
    }
  } catch (error) {
    console.error('Login error:', error);
    res.status(400).json({ 
      success: false,
      message: error.message 
    });
  }
});

// Complaint submission endpoint
app.post('/complaints', async (req, res) => {
  console.log('Received complaint submission request');
  
  const validation = {
    category: Boolean(req.body.category),
    title: Boolean(req.body.title),
    description: Boolean(req.body.description),
    userName: Boolean(req.body.userName)
  };

  if (!validation.category || !validation.title || !validation.description || !validation.userName) {
    const missingFields = Object.entries(validation)
      .filter(([_, value]) => !value)
      .map(([key]) => key);
    
    return res.status(400).json({ 
      message: 'Missing required fields', 
      missingFields: missingFields 
    });
  }

  try {
    const complaintId = await generateComplaintId();
    const currentTime = new Date();
    
    const complaintData = {
      complaintId,
      category: req.body.category,
      title: req.body.title,
      description: req.body.description,
      userName: req.body.userName,
      timeline: [{
        status: 'Pending',
        timestamp: currentTime,
        comment: 'Complaint submitted'
      }]
    };

    // Add image if provided
    if (req.body.image) {
      complaintData.image = req.body.image;
    }

    const complaint = new Complaint(complaintData);
    await complaint.save();

    console.log('Complaint lodged successfully:', complaintId);

    res.status(201).json({
      success: true,
      message: 'Complaint lodged successfully',
      complaintId: complaintId
    });
  } catch (error) {
    console.error('Complaint submission error:', error);
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

// Get complaints by userName
app.get('/complaints/:userName', async (req, res) => {
  try {
    const complaints = await Complaint.find({ userName: req.params.userName })
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      complaints: complaints.map(complaint => ({
        ...complaint.toObject(),
        hasImage: Boolean(complaint.image) // Add flag to indicate image presence
      }))
    });
  } catch (error) {
    console.error('Error fetching complaints:', error);
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

// Reopen complaint endpoint
app.post('/complaints/reopen/:complaintId', async (req, res) => {
  try {
    const currentTime = new Date(); // Get current system time
    const complaint = await Complaint.findOneAndUpdate(
      { complaintId: req.params.complaintId },
      { 
        status: 'Reopened',
        $push: {
          timeline: {
            status: 'Reopened',
            timestamp: currentTime, // Use exact system time
            comment: 'Complaint reopened by user'
          }
        }
      },
      { new: true }
    );

    if (!complaint) {
      return res.status(404).json({
        success: false,
        message: 'Complaint not found'
      });
    }

    res.json({
      success: true,
      message: 'Complaint reopened successfully',
      complaint: complaint
    });
  } catch (error) {
    console.error('Error reopening complaint:', error);
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

// Get complaint by ID endpoint
app.get('/complaints/track/:complaintId', async (req, res) => {
  try {
    const complaint = await Complaint.findOne({ complaintId: req.params.complaintId });
    
    if (!complaint) {
      return res.status(404).json({
        success: false,
        message: 'Complaint not found'
      });
    }

    res.json({
      success: true,
      complaint: complaint
    });
  } catch (error) {
    console.error('Error fetching complaint:', error);
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

// Admin dashboard data endpoint
app.get('/admin/dashboard', async (req, res) => {
  try {
    const totalComplaints = await Complaint.countDocuments();
    const pendingComplaints = await Complaint.countDocuments({ status: 'Pending' });
    const inProgressComplaints = await Complaint.countDocuments({ status: 'In Progress' });
    const resolvedComplaints = await Complaint.countDocuments({ status: 'Resolved' });
    const reopenedComplaints = await Complaint.countDocuments({ status: 'Reopened' });

    // Get category distribution
    const categoryData = await Complaint.aggregate([
      { $group: { _id: "$category", count: { $sum: 1 } } }
    ]);

    // Get trend data (last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const trendData = await Complaint.aggregate([
      {
        $match: {
          createdAt: { $gte: sevenDaysAgo }
        }
      },
      {
        $group: {
          _id: { 
            date: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
            category: "$category",
            status: "$status"
          },
          count: { $sum: 1 },
          avgResponseTime: { $avg: "$responseTime" },
          reopenCount: {
            $sum: {
              $cond: [{ $eq: ["$status", "Reopened"] }, 1, 0]
            }
          }
        }
      },
      { 
        $group: {
          _id: "$_id.date",
          total: { $sum: "$count" },
          resolved: {
            $sum: {
              $cond: [{ $eq: ["$_id.status", "Resolved"] }, "$count", 0]
            }
          },
          categoryData: {
            $push: {
              category: "$_id.category",
              count: "$count"
            }
          },
          avgResponseTime: { $avg: "$avgResponseTime" },
          reopenCount: { $sum: "$reopenCount" }
        }
      },
      { $sort: { "_id": 1 } }
    ]);

    // Get recent complaints
    const recentComplaints = await Complaint.find()
      .sort({ createdAt: -1 })
      .limit(5);

    // Update monthly complaints aggregation for better filtering
    const monthlyComplaints = await Complaint.aggregate([
      {
        $group: {
          _id: {
            yearMonth: { $dateToString: { format: "%Y-%m", date: "$createdAt" } },
            status: "$status",
            category: "$category"
          },
          count: { $sum: 1 },
          complaints: { $push: "$$ROOT" }
        }
      },
      {
        $group: {
          _id: "$_id.yearMonth",
          statuses: {
            $push: {
              status: "$_id.status",
              category: "$_id.category",
              count: "$count",
              complaints: "$complaints"
            }
          },
          totalCount: { $sum: "$count" }
        }
      },
      { $sort: { "_id": -1 } }
    ]);

    // Update category distribution aggregation
    const categoryDistribution = await Complaint.aggregate([
      {
        $group: {
          _id: "$category",
          count: { $sum: 1 },
          complaints: {
            $push: {
              complaintId: "$complaintId",
              status: "$status",
              createdAt: "$createdAt"
            }
          }
        }
      },
      {
        $sort: { "_id": 1 }
      }
    ]);

    res.json({
      success: true,
      data: {
        overview: {
          total: totalComplaints,
          pending: pendingComplaints,
          inProgress: inProgressComplaints,
          resolved: resolvedComplaints,
          reopened: reopenedComplaints
        },
        categoryDistribution: categoryDistribution,
        monthlyComplaints: monthlyComplaints,
        recentComplaints: recentComplaints
      }
    });
  } catch (error) {
    console.error('Error fetching dashboard data:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Get all complaints with filters
app.get('/complaints', async (req, res) => {
  try {
    const { status, category, sortBy = 'createdAt', order = 'desc' } = req.query;
    const query = {};
    
    if (status && status !== 'All') {
      query.status = status;
    }
    if (category && category !== 'All') {
      query.category = category;
    }

    const complaints = await Complaint.find(query)
      .lean()  // Convert to plain JavaScript objects
      .sort({ [sortBy]: order });

    // Fetch user details for each complaint
    const complaintsWithUserDetails = await Promise.all(
      complaints.map(async (complaint) => {
        const user = await User.findOne({ name: complaint.userName }).lean();
        return {
          ...complaint,
          registrationNumber: user ? user.registrationNumber : 'N/A'
        };
      })
    );

    res.json({
      success: true,
      complaints: complaintsWithUserDetails
    });
  } catch (error) {
    console.error('Error fetching complaints:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Update complaint status with comment
app.post('/complaints/update/:complaintId', async (req, res) => {
  try {
    const { status, comment } = req.body;
    const currentTime = new Date();
    
    const complaint = await Complaint.findOneAndUpdate(
      { complaintId: req.params.complaintId },
      {
        status: status,
        $push: {
          timeline: {
            status: status,
            timestamp: currentTime,
            comment: comment || `Status updated to ${status}`
          }
        }
      },
      { new: true }
    );

    if (!complaint) {
      return res.status(404).json({
        success: false,
        message: 'Complaint not found'
      });
    }

    res.json({
      success: true,
      message: 'Complaint updated successfully',
      complaint: complaint
    });
  } catch (error) {
    console.error('Error updating complaint:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

app.get('/reports/generate', async (req, res) => {
  try {
    const { startDate, endDate, status, category } = req.query;
    const query = {};

    if (startDate && endDate) {
      query.createdAt = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }
    
    if (status && status !== 'All') {
      query.status = status;
    }
    
    if (category && category !== 'All') {
      query.category = category;
    }

    const complaints = await Complaint.find(query).sort({ createdAt: -1 });

    // Update timelineData aggregation to include dates without complaints
    const timelineData = await Complaint.aggregate([
      { $match: query },
      {
        $group: {
          _id: {
            $dateToString: { format: "%Y-%m-%d", date: "$createdAt" }
          },
          count: { $sum: 1 }
        }
      },
      { $sort: { "_id": 1 } }
    ]);

    // Fill in missing dates with zero counts
    const filledTimelineData = _fillMissingDates(timelineData, startDate, endDate);

    // Generate analytics data
    const analytics = {
      totalComplaints: complaints.length,
      statusDistribution: await Complaint.aggregate([
        { $match: query },
        { $group: { _id: "$status", count: { $sum: 1 } } },
        { $sort: { "_id": 1 } }
      ]),
      categoryDistribution: await Complaint.aggregate([
        { $match: query },
        { $group: { _id: "$category", count: { $sum: 1 } } },
        { $sort: { "_id": 1 } }
      ]),
      timelineData: filledTimelineData
    };

    res.json({
      success: true,
      complaints,
      analytics
    });
  } catch (error) {
    console.error('Error generating report:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

function _fillMissingDates(timelineData, startDate, endDate) {
  if (!startDate || !endDate || timelineData.length === 0) return timelineData;

  const start = new Date(startDate);
  const end = new Date(endDate);
  const result = [];
  const dataMap = new Map(timelineData.map(item => [item._id, item.count]));

  for (let date = start; date <= end; date.setDate(date.getDate() + 1)) {
    const dateStr = date.toISOString().split('T')[0];
    result.push({
      _id: dateStr,
      count: dataMap.get(dateStr) || 0
    });
  }

  return result;
}

// Add endpoint to get complaint image
app.get('/complaints/image/:complaintId', async (req, res) => {
  try {
    const complaint = await Complaint.findOne({ complaintId: req.params.complaintId });
    
    if (!complaint || !complaint.image) {
      return res.status(404).json({
        success: false,
        message: 'Image not found'
      });
    }

    res.json({
      success: true,
      image: complaint.image
    });
  } catch (error) {
    console.error('Error fetching complaint image:', error);
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

// Add route not found handler
app.use((req, res) => {
  res.status(404).json({ message: `Route ${req.url} not found` });
});

app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});