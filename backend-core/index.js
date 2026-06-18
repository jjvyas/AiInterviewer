require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const PORT = process.env.PORT || 3000;
const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:8000';

// Initialize Supabase Client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceRoleKey) {
  console.warn('WARNING: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in env.');
}

const supabase = createClient(supabaseUrl || 'https://placeholder.supabase.co', supabaseServiceRoleKey || 'placeholder');

// Global Middlewares
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));

// Auth middleware to validate Supabase User JWT
const requireAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      if (process.env.NODE_ENV === 'development') {
        console.warn('Dev Mode: Missing or invalid Bearer token. Bypassing auth with mock user.');
        req.user = { id: '00000000-0000-0000-0000-000000000000', email: 'mockuser@example.com' };
        return next();
      }
      return res.status(401).json({ error: 'Unauthorized: Missing or invalid token format' });
    }

    const token = authHeader.split(' ')[1];
    
    // In production, validate token against Supabase
    let user = null;
    let authError = null;
    try {
      const { data, error } = await supabase.auth.getUser(token);
      user = data?.user;
      authError = error;
    } catch (err) {
      authError = err;
    }
    
    if (authError || !user) {
      if (process.env.NODE_ENV === 'development') {
        console.warn('Dev Mode: Supabase token verification failed. Bypassing auth with mock user.', authError);
        req.user = { id: '00000000-0000-0000-0000-000000000000', email: 'mockuser@example.com' };
        return next();
      }
      return res.status(401).json({ error: 'Unauthorized: Invalid token' });
    }

    req.user = user;
    next();
  } catch (err) {
    console.error('Auth middleware error:', err);
    if (process.env.NODE_ENV === 'development') {
      console.warn('Dev Mode: Exception in auth middleware. Bypassing auth with mock user.');
      req.user = { id: '00000000-0000-0000-0000-000000000000', email: 'mockuser@example.com' };
      return next();
    }
    res.status(500).json({ error: 'Internal server error during auth verification' });
  }
};

// Endpoints

// Health Check / Config
app.get('/api/health', (req, res) => {
  res.json({
    status: 'UP',
    timestamp: new Date().toISOString(),
    aiServiceUrl: AI_SERVICE_URL
  });
});

// Create a new Interview Session
app.post('/api/interviews/session', requireAuth, async (req, res) => {
  const { domain, experienceTier, resumeContext } = req.body;
  if (!domain || !experienceTier) {
    return res.status(400).json({ error: 'domain and experienceTier are required' });
  }

  try {
    const { data, error } = await supabase
      .from('interviews')
      .insert({
        user_id: req.user.id,
        domain: domain,
        experience_tier: experienceTier,
        current_step: 1,
        resume_context: resumeContext || null
      })
      .select()
      .single();

    if (error) {
      console.error('Supabase error inserting interview:', error);
      if (process.env.NODE_ENV === 'development') {
        console.warn('Dev Mode: Supabase insertion failed. Returning mock interview session.');
        const mockInterview = {
          id: require('crypto').randomUUID ? require('crypto').randomUUID() : '00000000-0000-0000-0000-000000000000',
          user_id: req.user.id,
          domain: domain,
          experience_tier: experienceTier,
          current_step: 1,
          resume_context: resumeContext || null,
          created_at: new Date().toISOString()
        };
        return res.status(201).json({
          message: 'Interview session created successfully (Dev Mock)',
          interview: mockInterview
        });
      }
      return res.status(500).json({ error: 'Failed to initialize session in database' });
    }

    res.status(201).json({
      message: 'Interview session created successfully',
      interview: data
    });
  } catch (err) {
    console.error('Failed to create session:', err);
    if (process.env.NODE_ENV === 'development') {
      console.warn('Dev Mode: Exception in session creation. Returning mock interview session.');
      const mockInterview = {
        id: require('crypto').randomUUID ? require('crypto').randomUUID() : '00000000-0000-0000-0000-000000000000',
        user_id: req.user.id,
        domain: domain,
        experience_tier: experienceTier,
        current_step: 1,
        resume_context: resumeContext || null,
        created_at: new Date().toISOString()
      };
      return res.status(201).json({
        message: 'Interview session created successfully (Dev Mock)',
        interview: mockInterview
      });
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Log Client Events & Status Syncing (automated logging task)
app.post('/api/logs', requireAuth, async (req, res) => {
  const { interviewId, eventType, message, clientState } = req.body;
  
  console.log(`[CLIENT-LOG] [User: ${req.user.id}] [Interview: ${interviewId}] [Event: ${eventType}] ${message || ''}`);
  if (clientState) {
    console.log(`[CLIENT-LOG] State detail:`, JSON.stringify(clientState));
  }

  // We can track heartbeats, state parameters or logs
  res.json({ status: 'LOGGED', synced: true });
});

// Resume Labs: Upload and forward to Python Service
app.post('/api/resume/upload', requireAuth, async (req, res) => {
  const { fileBytes, fileName, targetJob } = req.body;
  if (!fileBytes) {
    return res.status(400).json({ error: 'fileBytes is required' });
  }

  try {
    console.log(`[RESUME-LABS] Received file: ${fileName || 'unnamed'} from User: ${req.user.id}`);
    
    // Call Python FastAPI Service
    const response = await fetch(`${AI_SERVICE_URL}/api/resume/analyze`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        fileBytes,
        fileName,
        targetJob: targetJob || ''
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('AI Service Error response:', errorText);
      return res.status(response.status).json({ error: `AI service error: ${errorText}` });
    }

    const aiAnalysisResult = await response.json();
    res.json(aiAnalysisResult);
  } catch (err) {
    console.error('Error in forwarding resume to AI service:', err);
    res.status(500).json({ error: 'Failed to communicate with AI parsing engine' });
  }
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('Unhandled express exception:', err);
  res.status(500).json({ error: 'An unexpected error occurred' });
});

app.listen(PORT, () => {
  console.log(`Express Backend core running on port ${PORT}`);
  console.log(`Connected to AI Service at: ${AI_SERVICE_URL}`);
});
