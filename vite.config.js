import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  build: {
    lib: {
      entry: resolve(__dirname, 'src/index.js'),
      name: 'amtabulator',
      fileName: () => 'amtabulator.js',  // Force .js extension
      formats: ['umd']
    },
    outDir: 'inst/htmlwidgets/dist',
    emptyOutDir: true,
    cssCodeSplit: false,
    rollupOptions: {
      output: {
        manualChunks: undefined,
        inlineDynamicImports: true,
        format: 'umd',
        entryFileNames: 'amtabulator.js'  // Ensure correct filename
      }
    }
  },
  test: {
    environment: 'jsdom',
    globals: true
  }
});
