/**
 * Style Manager for handling dynamic CSS loading
 */
export class StyleManager {
  constructor() {
    this.loadedStyles = new Map();
  }

  /**
   * Create and insert a style element
   * @param {string} content - CSS content
   * @param {string} id - Style element ID
   * @private
   */
  _createStyle(content, id) {
    // Remove existing style if it exists
    this.removeStyle(id);
    
    const style = document.createElement('style');
    style.id = id;
    style.textContent = content;
    document.head.appendChild(style);
    this.loadedStyles.set(id, style);
  }

  /**
   * Load a theme's styles
   * @param {string} themeName - Theme identifier
   * @param {boolean} compact - Whether to apply compact styling (default: true)
   * @returns {Promise<void>}
   */
  async loadTheme(themeName = 'bootstrap4', compact = true) {
    try {
      let cssModule;
      
      switch(themeName) {
        case 'bootstrap3':
          cssModule = await import('tabulator-tables/dist/css/tabulator_bootstrap3.min.css');
          break;
        case 'bootstrap5':
          cssModule = await import('tabulator-tables/dist/css/tabulator_bootstrap5.min.css');
          break;
        case 'modern':
          cssModule = await import('tabulator-tables/dist/css/tabulator_modern.min.css');
          break;
        case 'simple':
          cssModule = await import('tabulator-tables/dist/css/tabulator_simple.min.css');
          break;
        case 'midnight':
          cssModule = await import('tabulator-tables/dist/css/tabulator_midnight.min.css');
          break;
        case 'materialize':
          cssModule = await import('tabulator-tables/dist/css/tabulator_materialize.min.css');
          break;
        case 'semantic':
          cssModule = await import('tabulator-tables/dist/css/tabulator_semanticui.min.css');
          break;
        case 'bootstrap4':
        default:
          cssModule = await import('tabulator-tables/dist/css/tabulator_bootstrap4.min.css');
          break;
      }

      this._createStyle(cssModule.default, `tabulator-theme-${themeName}`);

      if (compact) {
        const compactStyles = await import('./style.css');
        this._createStyle(compactStyles.default, 'tabulator-compact-style');
      }

    } catch (error) {
      console.error(`Failed to load theme ${themeName}:`, error);
      if (themeName !== 'bootstrap4') {
        return this.loadTheme('bootstrap4', compact);
      }
      throw error;
    }
  }

  /**
   * Remove a specific style
   * @param {string} styleId - Style identifier
   */
  removeStyle(styleId) {
    const style = this.loadedStyles.get(styleId);
    if (style) {
      style.remove();
      this.loadedStyles.delete(styleId);
    }
  }

  /**
   * Remove all loaded styles
   */
  removeAllStyles() {
    for (const [styleId] of this.loadedStyles) {
      this.removeStyle(styleId);
    }
  }
}

// Singleton instance
export const styleManager = new StyleManager();
