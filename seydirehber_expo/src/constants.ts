// Flutter lib/core/constants/app_constants.dart karşılığı.
export const GOOGLE_PLAY_LINK = 'https://play.google.com/store/apps/details?id=com.mgverse.seydirehberim';
export const APP_STORE_LINK = 'https://apps.apple.com/tr/app/seydi-rehber/id6762803524';

const SHARE_APP_LINKS = `\n\n📱 Android (Google Play):\n${GOOGLE_PLAY_LINK}\n\n🍏 iOS (App Store):\n${APP_STORE_LINK}`;

export const getShareText = (message: string) => `${message}${SHARE_APP_LINKS}`;
