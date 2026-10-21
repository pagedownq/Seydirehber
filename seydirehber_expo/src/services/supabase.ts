import 'react-native-url-polyfill/auto';

import { createClient } from '@supabase/supabase-js';

// Supabase sadece Storage (görseller) için kullanılıyor; oturum tutulmaz.
export const supabase = createClient(
  process.env.EXPO_PUBLIC_SUPABASE_URL!,
  process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!,
  {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  },
);
