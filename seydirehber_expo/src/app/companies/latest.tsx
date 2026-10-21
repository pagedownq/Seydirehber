import { useAllLatestCompanies } from '@/features/home/home-queries';
import { GenericListScreen } from '@/screens/generic-list-screen';

export default function LatestCompaniesRoute() {
  return (
    <GenericListScreen
      title="Yeni Eklenen Firmalar"
      useQuery={useAllLatestCompanies}
      routePrefix="companies"
      showViewCount
      cacheKey="companies_latest_cache"
    />
  );
}
