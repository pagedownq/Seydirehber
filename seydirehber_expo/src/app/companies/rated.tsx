import { useAllTopRatedCompanies } from '@/features/home/home-queries';
import { GenericListScreen } from '@/screens/generic-list-screen';

export default function RatedCompaniesRoute() {
  return (
    <GenericListScreen
      title="En Çok Değerlendirme Alanlar"
      useQuery={useAllTopRatedCompanies}
      routePrefix="companies"
      showViewCount
      showRating
      cacheKey="companies_rated_cache"
    />
  );
}
