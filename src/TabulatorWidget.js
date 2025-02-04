import { TabulatorFull as Tabulator } from "tabulator-tables";
import { TabulatorToolbar } from "./TabulatorToolbar.js";
import { styleManager } from './styleManager';

export class TabulatorWidget {
  constructor(el, callbacks) {
    this.el = el;
    this.table = null;
    this.callbacks = callbacks;
    this._options = {};
    this.currentTheme = null;
  }

  async init(config, callbacks) {
    const tw = this;
    if (tw.table) {
      tw.destroy();
    }

    const { options } = config;
    const { data } = options;

    // Load theme before initializing table
    const themeName = options.theme_id || 'bootstrap4';
    const compact = options.compact !== undefined ? options.compact : true;
    
    if (this.currentTheme !== themeName) {
      await styleManager.loadTheme(themeName, compact);
      this.currentTheme = themeName;
    }

    tw._options = options;
    try {
      if (data) {
        options.data = tw.formatTable(data);
      }

      /**
       * Handle select checkbox selection
       */
      if (options.return_select_column) {
        options.add_select_column = true;
      }
      if (options.add_select_column) {
        options.columns = [tw.createSelectCol(), ...options.columns];
      }

      /**
       * Init
       */
      tw.table = new Tabulator(tw.el, options);

      /**
       * Add callbacks
       */
      tw.registerCallbacks(callbacks);

      /**
       * Add selector bar
       */
      tw.table.on("tableBuilt", function () {
        if (options.add_selector_bar) {
          tw.elSelector = document.createElement("div");
          tw.el.prepend(tw.elSelector);
          const toolsBar = new TabulatorToolbar(tw.table, tw.elSelector);
          tw.el.classList.add("tabulator-with-toolbar");
          toolsBar.createToolbar();
        }
      });
      /**
       * Freeze row
       */
      if (options.freeze_selected) {
        tw.table.on(
          "rowSelectionChanged",
          function (data, rows, selected, deselected) {
            tw.table.blockRedraw();
            for (const row of selected) {
              row.freeze();
            }
            for (const row of deselected) {
              row.unfreeze();
            }
            tw.table.restoreRedraw();
          }
        );
      }
    } catch (error) {
      console.error("Error creating Tabulator instance:", error);
    }
  }

  registerCallbacks(cbs) {
    const tw = this;
    if (cbs) {
      for (const [type, action] of cbs) {
        const action_debounce = tw.debounce(action);

        if (Array.isArray(type)) {
          for (const t of type) {
            tw.table.on(t, action_debounce);
          }
        } else {
          tw.table.on(type, action_debounce);
        }
      }
    }
  }

  debounce(func, timeout = 300) {
    let timer;
    return (...args) => {
      if (timer) {
        clearTimeout(timer);
      }
      timer = setTimeout(() => {
        func.apply(this, args);
      }, timeout);
    };
  }

  get options() {
    return this._options;
  }

  resize(_, __) {
    if (this.table) {
      this.table.redraw(true);
    }
  }

  createSelectCol() {
    const col = {
      formatter: "rowSelection",
      titleFormatter: "rowSelection",
      headerSort: false,
      width: 50,
      headerFilter: false,
      frozen: true,
      headerTooltip: false,
      tooltip: false,
      resizable: false,
    };
    return col;
  }

  getData() {
    const tw = this;
    if (!tw._options?.return_select_column) {
      return tw.table.getData();
    } else {
      const field = tw._options?.return_select_column_name || "row_select";
      const rows = tw.table.getRows();
      return rows.map((row) => {
        const s = {};
        s[field] = row.isSelected();
        return { ...row.getData(), ...s };
      });
    }
  }

  getTable() {
    return this.table;
  }

  destroy() {
    if (this.table) {
      this.table.destroy();
      this.table = null;
    }
  }

  async update(action, value) {
    if (!this.table) {
      console.error("Table instance not found");
      return;
    }

    try {
      switch (action) {
        case "update_data":
          await this.updateData(value);
          break;
        case "update_where":
          await this.updateWhere(value);
          break;
        case "replace_data":
          await this.replaceData(value);
          break;
        default:
          console.warn("Unknown action:", action);
      }
    } catch (error) {
      console.error("Error handling tabulator update:", error);
    }
  }

  filter(filterFunc) {
    this.table.setFilter(filterFunc);
  }

  async updateData({ data, chunk, total_chunks }) {
    try {
      const formattedData = this.formatTable(data);
      if (this.options.index) {
        await this.table.updateOrAddData(formattedData);
      } else {
        await this.table.replaceData(formattedData);
      }

      if (chunk === total_chunks) {
        this.table.setData(this.table.getData());
      }
    } catch (error) {
      console.error("Error updating data:", error);
    }
  }

  async replaceData(data) {
    try {
      const formattedData = this.formatTable(data);
      await this.table.setData(formattedData);
    } catch (error) {
      console.error("Error replacing data:", error);
    }
  }

  async updateWhere({
    col,
    value,
    whereCol,
    whereValue,
    operator,
    chunk_size,
  }) {
    const matchingRows = this.table.searchRows(whereCol, operator, whereValue);

    for (
      let startIndex = 0;
      startIndex < matchingRows.length;
      startIndex += chunk_size
    ) {
      const endIndex = Math.min(startIndex + chunk_size, matchingRows.length);
      const updateData = matchingRows
        .slice(startIndex, endIndex)
        .map((row) => ({ ...row.getData(), [col]: value }));

      try {
        await this.table.updateData(updateData);
      } catch (error) {
        console.error("Error updating data:", error);
        return;
      }

      await new Promise((resolve) => setTimeout(resolve, 0));
    }

    this.table.setData(this.table.getData());
  }

  formatTable(objOfArrays) {
    if (Array.isArray(objOfArrays)) {
      return objOfArrays;
    }
    const keys = Object.keys(objOfArrays);
    const length = objOfArrays[keys[0]].length;
    if (!length) {
      return [objOfArrays];
    }
    return Array.from({ length }, (_, i) =>
      Object.fromEntries(keys.map((key) => [key, objOfArrays[key][i]]))
    );
  }

  async addRows(data, position = "bottom") {
    if (!this.table) {
      console.error("Table instance not found");
      return;
    }

    try {
      const formattedData = this.formatTable(data, true);
      await this.table.addData(formattedData, position === "top");

      const updatedData = await this.table.getData();
      this.table.setData(updatedData);
    } catch (error) {
      console.error("Error adding rows:", error);
    }
  }

  async removeRows(rowIds) {
    if (!this.table) {
      console.error("Table instance not found");
      return;
    }

    try {
      if (!Array.isArray(rowIds)) {
        rowIds = [rowIds];
      }

      const rows = rowIds
        .map((id) => this.table.getRow(id))
        .filter((row) => row);

      rows.forEach((row) => row.delete());

      const updatedData = await this.table.getData();
      this.table.setData(updatedData);
    } catch (error) {
      console.error("Error removing rows:", error);
    }
  }

  async removeFirstRow() {
    if (!this.table) {
      console.error("Table instance not found");
      return;
    }

    try {
      const firstRow = this.table.getRows()[0];
      if (firstRow) {
        firstRow.delete();

        const updatedData = await this.table.getData();
        this.table.setData(updatedData);
      }
    } catch (error) {
      console.error("Error removing first row:", error);
    }
  }

  async removeLastRow() {
    if (!this.table) {
      console.error("Table instance not found");
      return;
    }

    try {
      const rows = this.table.getRows();
      const lastRow = rows[rows.length - 1];
      if (lastRow) {
        lastRow.delete();

        const updatedData = await this.table.getData();
        this.table.setData(updatedData);
      }
    } catch (error) {
      console.error("Error removing last row:", error);
    }
  }
}
