import { useLocalSearchParams } from 'expo-router';

import { SearchScreen } from '@/screens/search-screen';

export default function SearchRoute() {
  const { q } = useLocalSearchParams<{ q?: string }>();
  return <SearchScreen initialQuery={q} />;
}
