import { create } from 'zustand';

import { getItem, setItem, StorageKeys } from '@/services/storage';

// Flutter router redirect'indeki onboarding_completed kontrolü. Kök layout bu değere göre
// /onboarding ile uygulamanın geri kalanı arasında geçiş yapar.
export const useOnboardingStore = create<{ completed: boolean }>(() => ({ completed: false }));

export async function loadOnboardingState() {
  const completed = (await getItem<boolean>(StorageKeys.onboardingCompleted)) ?? false;
  useOnboardingStore.setState({ completed });
  return completed;
}

export async function completeOnboarding() {
  await setItem(StorageKeys.onboardingCompleted, true);
  useOnboardingStore.setState({ completed: true });
}
