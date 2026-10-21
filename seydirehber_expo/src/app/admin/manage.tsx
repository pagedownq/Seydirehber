import { useLocalSearchParams } from 'expo-router';

import { AdminManageScreen } from '@/screens/admin/admin-manage-screen';

// Flutter: context.push('/admin/manage', extra: {collection, title, bucket}).
export default function AdminManageRoute() {
  const { collection, title, bucket } = useLocalSearchParams<{ collection: string; title: string; bucket?: string }>();
  return (
    <AdminManageScreen
      key={collection}
      collectionName={collection}
      title={title ?? ''}
      bucket={bucket ? bucket : null}
    />
  );
}
