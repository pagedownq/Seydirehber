import { Alert } from 'react-native';

/** Flutter AlertDialog / CupertinoAlertDialog ile onay: platformun kendi uyarı penceresi. */
export function alertConfirm(options: {
  title: string;
  content: string;
  confirmText?: string;
  cancelText?: string;
  isDestructive?: boolean;
}): Promise<boolean> {
  const { title, content, confirmText = 'Evet', cancelText = 'Vazgeç', isDestructive = false } = options;
  return new Promise((resolve) => {
    Alert.alert(
      title,
      content,
      [
        { text: cancelText, style: 'cancel', onPress: () => resolve(false) },
        { text: confirmText, style: isDestructive ? 'destructive' : 'default', onPress: () => resolve(true) },
      ],
      { cancelable: true, onDismiss: () => resolve(false) },
    );
  });
}
