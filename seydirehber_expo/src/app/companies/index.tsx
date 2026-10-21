import { useAllCompanies } from '@/features/home/home-queries';
import { GenericListScreen } from '@/screens/generic-list-screen';

export default function CompaniesRoute() {
  return (
    <GenericListScreen
      title="Tüm Firmalar"
      useQuery={useAllCompanies}
      routePrefix="companies"
      showViewCount
      cacheKey="companies_all_cache"
    />
  );
}
