// Supabase credentials
const String supabaseUrl = 'https://zkphbmcvaiofabwzmiqa.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InprcGhibWN2YWlvZmFid3ptaXFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1ODQwOTgsImV4cCI6MjEwMzE2MDA5OH0.qsPSTy3i-xNW_Yojzzs9GkVOfwYcJ3YmczRYRlpM_5Y';

// Gemini API key (can be passed via --dart-define=GEMINI_API_KEY=your_key or pasted here)
const String geminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: 'YOUR_GEMINI_API_KEY_HERE',
);

// Storage bucket
const String storageBucket = 'problem-images';
const String uploadPrefix = 'citizen-uploads';

// Predefined departments (strict contract)
const List<String> departments = [
  'Public Works',
  'Water Supply & Sanitation',
  'Electricity',
  'Municipal Solid Waste',
  'Health',
  'Transport',
  'Urban Development',
  'Environment & Forests',
];

// Priority levels
const List<String> priorities = ['critical', 'high', 'medium', 'low'];

// Status values
const List<String> statuses = [
  'submitted',
  'under_review',
  'government_handling',
  'released',
  'interest_expressed',
  'in_progress',
  'resolved',
  'rejected',
];

// Category filter options for the UI
const List<String> categoryFilters = [
  'All',
  'Road Infrastructure',
  'Waste Management',
  'Public Lighting',
  'Water Supply',
  'Health & Sanitation',
  'Transport',
  'Urban Development',
  'Environment',
];

// Default reporter name
const String defaultReporterName = 'Citizen report · mobile app';
