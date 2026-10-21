import { useLocalSearchParams } from 'expo-router';

import { JobDetailScreen } from '@/screens/job-detail-screen';

export default function JobDetailRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <JobDetailScreen key={id} jobId={id} />;
}
