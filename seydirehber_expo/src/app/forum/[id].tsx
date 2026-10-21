import { useLocalSearchParams } from 'expo-router';

import { ForumDetailScreen } from '@/screens/forum-detail-screen';

export default function ForumDetailRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <ForumDetailScreen key={id} postId={id} />;
}
