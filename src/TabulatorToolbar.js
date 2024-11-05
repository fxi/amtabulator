import "./style.css";

export class TabulatorToolbar {
  constructor(table, targetElement) {
    this._table = table;
    this._targetElement = targetElement;
    this._elToolbar = null;
    this._elColSelector = null;
    this._elOpSelector = null;
    this._elValueInput = null;
  }

  createToolbar() {
    this._elToolbar = this.createElement("div", "tabulator-toolbar");

    const selectionControls = this.createSelectionControls();
    this._elColSelector = this.createColumnSelector();
    this._elOpSelector = this.createOperatorSelector();
    this._elValueInput = this.createValueInput();
    const actionButtons = this.createActionButtons();

    this._elToolbar.appendChild(selectionControls);
    this._elToolbar.appendChild(this._elColSelector);
    this._elToolbar.appendChild(this._elOpSelector);
    this._elToolbar.appendChild(this._elValueInput);
    this._elToolbar.appendChild(actionButtons);

    this._targetElement.appendChild(this._elToolbar);

    this.setupEventListeners();
    this.onColumnChange();
  }

  createSelectionControls() {
    const container = this.createElement("span", "selection-controls");
    container.appendChild(
      this.createLinkButton("[All]", () => this.selectAll())
    );
    container.appendChild(document.createTextNode(" "));
    container.appendChild(
      this.createLinkButton("[None]", () => this.selectNone())
    );
    return container;
  }

  createColumnSelector() {
    const selector = this.createElement("select", "column-selector");
    let selected = true;
    this._table.getColumns().forEach((column) => {
      const label = column.getDefinition().title || column.getField();
      const field = column.getField();
      if (!label || !field) {
        return;
      }
      selector.appendChild(this.createOption(field, label, selected));
      selected = false;
    });
    return selector;
  }

  createOperatorSelector() {
    const selector = this.createElement("select", "operator-selector");
    return selector;
  }

  createValueInput() {
    return this.createElement("input", "value-input");
  }

  createActionButtons() {
    const container = this.createElement("span", "action-buttons");
    container.appendChild(
      this.createLinkButton("[Select]", () => this.applySelection(true))
    );
    container.appendChild(document.createTextNode(" "));
    container.appendChild(
      this.createLinkButton("[Unselect]", () => this.applySelection(false))
    );
    return container;
  }

  setupEventListeners() {
    this._elColSelector.addEventListener("change", () => this.onColumnChange());
    this._elOpSelector.addEventListener("change", () =>
      this.onOperatorChange()
    );
    this._elValueInput.addEventListener("input", () => this.onValueInput());
  }

  onColumnChange() {
    const column = this._table.getColumn(this._elColSelector.value);
    this._elOpSelector.innerHTML = "";

    if (column) {
      const dataType = this.getColumnDataType(column);
      const operators =
        dataType === "number"
          ? ["=", "!=", ">", "<", ">=", "<="]
          : ["=", "!=", "like"];
      operators.forEach((op) =>
        this._elOpSelector.appendChild(this.createOption(op, op))
      );

      const newInput = this.createAppropriateInput(column, dataType);
      this._elToolbar.replaceChild(newInput, this._elValueInput);
      this._elValueInput = newInput;
    }
  }

  onOperatorChange() {
    // Placeholder for any future operator-specific logic
  }

  onValueInput() {
    // Placeholder for any future value-specific logic
  }

  getColumnDataType(column) {
    const firstRow = this._table.getData()[0];
    return typeof firstRow[column.getField()];
  }

  createAppropriateInput(column, dataType) {
    if (dataType === "string") {
      const uniqueValues = new Set(
        this._table.getData().map((row) => row[column.getField()])
      );
      if (uniqueValues.size <= 200) {
        const select = this.createElement("select", "value-input");
        Array.from(uniqueValues)
          .sort()
          .forEach((value) => {
            select.appendChild(this.createOption(value, value));
          });
        return select;
      }
    }

    const input = this.createElement("input", "value-input");
    input.type = dataType === "number" ? "number" : "text";
    return input;
  }

  applySelection(select) {
    const field = this._elColSelector.value;
    const operator = this._elOpSelector.value;
    const value = this._elValueInput.value;

    if (!field || !operator || value === "") return;

    const matchingRows = this._table.searchRows(field, operator, value);
    matchingRows.forEach((row) => {
      if (select) {
        row.select();
      } else {
        row.deselect();
      }
    });
  }

  selectAll() {
    this._table.selectRow();
  }

  selectNone() {
    this._table.deselectRow();
  }

  // Helper methods for creating HTML elements
  createElement(tag, className) {
    const element = document.createElement(tag);
    if (className) {
      element.className = className;
    }
    return element;
  }

  createOption(value, text, selected = false) {
    const option = this.createElement("option");
    option.value = value;
    option.textContent = text;
    if (selected) {
      option.setAttribute("selected", true);
    }
    return option;
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
