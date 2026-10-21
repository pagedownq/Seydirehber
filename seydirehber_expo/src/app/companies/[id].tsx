import { useLocalSearchParams } from 'expo-router';

import { CompanyDetailScreen } from '@/screens/company-detail-screen';

export default function CompanyDetailRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <CompanyDetailScreen companyId={id} />;
}
