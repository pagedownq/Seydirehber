// Flutter lib/core/constants/app_colors.dart + lib/core/theme/app_theme.dart karşılığı.
// Renk, font ve ölçüler sadece buradan okunur.

export const colors = {
  primary: '#4CAF50',
  primaryLight: '#81C784',
  primaryDark: '#388E3C',
  primarySurface: '#E8F5E9',
  accent: '#66BB6A',

  background: '#F5F9F6',
  white: '#FFFFFF',
  surface: '#FFFFFF',

  textPrimary: '#1B1B1B',
  textSecondary: '#6B6B6B',
  textLight: '#9E9E9E',
  textOnPrimary: '#FFFFFF',

  cardBackground: '#FFFFFF',
  border: '#E0E0E0',
  divider: '#F0F0F0',

  error: '#E53935',
  success: '#43A047',
  warning: '#FFA726',
  info: '#29B6F6',

  shimmerBase: '#E0E0E0',
  shimmerHighlight: '#F5F5F5',

  // Flutter Colors.* karşılıkları (widget'larda doğrudan kullanılanlar)
  black87: 'rgba(0, 0, 0, 0.87)',
  grey200: '#EEEEEE',
  grey600: '#757575',
  red800: '#C62828',
  barrier: 'rgba(0, 0, 0, 0.54)',
} as const;

// Flutter: begin topLeft → end bottomRight
export const gradients = {
  primary: ['#66BB6A', '#43A047'],
  card: ['#E8F5E9', '#C8E6C9'],
  weather: ['#2196F3', '#00BCD4'],
} as const;

export const gradientDirection = {
  start: { x: 0, y: 0 },
  end: { x: 1, y: 1 },
} as const;

export const fonts = {
  regular: 'Poppins_400Regular',
  medium: 'Poppins_500Medium',
  semiBold: 'Poppins_600SemiBold',
  bold: 'Poppins_700Bold',
  extraBold: 'Poppins_800ExtraBold',
  black: 'Poppins_900Black',
} as const;

export const radius = {
  card: 16,
  button: 12,
  input: 12,
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
} as const;

// Flutter CardTheme: elevation 1, shadowColor black12
export const shadow = {
  card: {
    shadowColor: '#000000',
    shadowOpacity: 0.12,
    shadowRadius: 2,
    shadowOffset: { width: 0, height: 1 },
    elevation: 1,
  },
} as const;

// Flutter lib/core/constants/app_text_styles.dart
export const typography = {
  heading1: { fontFamily: fonts.bold, fontSize: 28, color: colors.textPrimary },
  heading2: { fontFamily: fonts.semiBold, fontSize: 22, color: colors.textPrimary },
  heading3: { fontFamily: fonts.semiBold, fontSize: 18, color: colors.textPrimary },
  bodyLarge: { fontFamily: fonts.regular, fontSize: 16, color: colors.textPrimary },
  bodyMedium: { fontFamily: fonts.regular, fontSize: 14, color: colors.textPrimary },
  bodySmall: { fontFamily: fonts.regular, fontSize: 12, color: colors.textSecondary },
  button: { fontFamily: fonts.semiBold, fontSize: 14, color: colors.textOnPrimary },
  caption: { fontFamily: fonts.regular, fontSize: 11, color: colors.textLight },
  sectionTitle: { fontFamily: fonts.bold, fontSize: 18, color: colors.textPrimary },
  appBarTitle: { fontFamily: fonts.bold, fontSize: 20, color: colors.primary },
} as const;
