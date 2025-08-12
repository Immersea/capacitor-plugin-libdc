import { registerPlugin } from '@capacitor/core';

import type { LibDCPlugin } from './definitions';

const LibDC = registerPlugin<LibDCPlugin>('LibDC', {
  web: () => import('./web').then(m => new m.LibDCWeb()),
});

export * from './definitions';
export { LibDC };