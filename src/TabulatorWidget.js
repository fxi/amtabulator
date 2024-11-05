import "tabulator-tables/dist/css/tabulator_bootstrap3.min.css";

import { TabulatorFull as Tabulator } from "tabulator-tables";
import { TabulatorToolbar } from "./TabulatorToolbar.js";

export class TabulatorWidget {
  constructor(el, callbacks) {
    this.el = el;
    this.table = null;
    this.callbacks = callbacks;
  }

  renderValue(x) {
    const tw = this;
    if (tw.table) {
      console.warn("Tabulator already initialized");
      return;
    }

    try {
      if (x.options.data) {
        x.options.data = tw.formatTable(x.options.data);
      }

      if (x.options.add_select_column) {
        x.options.columns = [tw.createSelectCol(), ...x.options.columns];
      }
      tw.table = new Tabulator(tw.el, x.options);

      tw.table.on("tableBuilt", function () {
        if (x.options.add_selector_bar) {
          tw.elSelector = document.createElement("div");
          tw.el.prepend(tw.elSelector);
          const toolsBar = new TabulatorToolbar(tw.table, tw.elSelector);
          toolsBar.createToolbar();
        }
        if (tw.callbacks) {
          for (const [type, action] of tw.callbacks) {
            tw.table.on(type, action);
          }
        }
      });
    } catch (error) {
      console.error("Error creating Tabulator instance:", error);
    }
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
      await this.table.updateData(formattedData);

      if (chunk === total_chunks) {
        this.table.setData(this.table.getData());
      }
    } catch (error) {
      console.error("Error updating data:", error);
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

      // Allow browser to remain responsive between chunks
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
    return Array.from({ length }, (_, i) =>
      Object.fromEntries(keys.map((key) => [key, objOfArrays[key][i]]))
    );
  }
}
