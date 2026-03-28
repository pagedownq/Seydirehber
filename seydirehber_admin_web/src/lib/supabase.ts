import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://ycqrgraqmafdtvaxwuml.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljcXJncmFxbWFmZHR2YXh3dW1sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM5MTI2MTgsImV4cCI6MjA4OTQ4ODYxOH0.riAGavZ3RZgUHwlxiQDp8PFmVju9qIUamOJBWS8kVWc';

export const supabase = createClient(supabaseUrl, supabaseKey);
