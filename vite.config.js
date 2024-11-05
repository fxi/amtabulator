import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  build: {
    lib: {
      entry: resolve(__dirname, 'src/index.js'),
      name: 'ShinyTabulator',
      fileName: () => 'shiny-tabulator.js',  // Force .js extension
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
        entryFileNames: 'shiny-tabulator.js'  // Ensure correct filename
      }
    }
  },
  test: {
    environment: 'jsdom',
    globals: true
  }
});
