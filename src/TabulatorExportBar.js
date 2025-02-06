export class TabulatorExportBar {
  constructor(table, elTarget, options = {}) {
    this._table = table;
    this._elExportBar = elTarget;
    this._options = options;
  }

  createExportBar() {
    this._elExportBar.classList.add("tabulator-export-bar");
    
    const exportControls = this.createExportControls();
    this._elExportBar.appendChild(exportControls);
  }

  createExportControls() {
    const container = this.createElement("span", "export-controls");
    const filename = this._options.export_filename || 'data';

    container.appendChild(
      this.createLinkButton("[Download CSV]", () => {
        this._table.download("csv", `${filename}.csv`);
      })
    );
    container.appendChild(document.createTextNode(" "));
    container.appendChild(
      this.createLinkButton("[Download JSON]", () => {
        this._table.download("json", `${filename}.json`);
      })
    );
    return container;
  }

  // Helper methods for creating HTML elements
  createElement(tag, className) {
    const element = document.createElement(tag);
    if (className) {
      element.className = className;
    }
    return element;
  }

  createLinkButton(text, onClick) {
    const button = this.createElement("a", "link-button");
    button.href = "#";
    button.textContent = text;
    button.addEventListener("click", (e) => {
      e.preventDefault();
      onClick();
    });
    return button;
  }
}
