import { doc, onSnapshot } from '@react-native-firebase/firestore';
import { useEffect, useState } from 'react';

import type { FirestoreData } from '@/features/firestore/live-query';
import { db } from '@/services/firebase';

// Flutter StreamBuilder<DocumentSnapshot>(stream: collection(x).doc(id).snapshots()) karşılığı.
export type DocumentState =
  | { status: 'loading'; data: null }
  | { status: 'missing'; data: null }
  | { status: 'error'; data: null; error: Error }
  | { status: 'ready'; data: FirestoreData };

type Keyed = { key: string; state: DocumentState };

export function useDocument(collectionPath: string, id: string): DocumentState {
  const key = `${collectionPath}/${id}`;
  const [current, setCurrent] = useState<Keyed>({ key, state: { status: 'loading', data: null } });

  useEffect(
    () =>
      onSnapshot(
        doc(db, collectionPath, id),
        (snapshot) => {
          const data = snapshot.data() as FirestoreData | undefined;
          setCurrent({
            key,
            state: snapshot.exists() && data ? { status: 'ready', data } : { status: 'missing', data: null },
          });
        },
        (error) => setCurrent({ key, state: { status: 'error', data: null, error } }),
      ),
    [collectionPath, id, key],
  );

  // Ekran başka bir dokümana geçtiyse eski sonuç gösterilmez.
  return current.key === key ? current.state : { status: 'loading', data: null };
}
