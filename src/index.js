import { TabulatorWidget } from "./TabulatorWidget";

HTMLWidgets.widget({
  name: "amtabulator",
  type: "output",
  renderOnNullValue: true,
  factory: function (el) {
    const elTable = document.createElement('div');
    el.appendChild(elTable);
    const widget = new TabulatorWidget(elTable);

    const callbacks = [
      [
        ["dataChanged", "dataLoaded", "rowSelectionChanged"],
        function () {
          /*
           * also updating input when selection change
           * - checkbox selection change the data
           *   when 'return_select_column' is true
           * - requesting data update with 'trigger_data' requires another step
           */
          Shiny.setInputValue(`${el.id}_data`, {
            data: JSON.stringify(widget.getData()),
          });
        },
      ],
      [
        ["rowSelectionChanged"],
        function (data) {
          Shiny.setInputValue(`${el.id}_selection`, {
            data: JSON.stringify(data),
          });
        },
      ],
      [
        ["cellEdited"],
        function (cell) {
          const data = {
            row: cell.getRow().getData(),
            column: cell.getColumn().getField(),
            oldValue: cell.getOldValue(),
            newValue: cell.getValue(),
          };

          Shiny.setInputValue(`${el.id}_cell_edit`, data);
        },
      ],
    ];

    return {
      renderValue: async (config) => await widget.init(config, callbacks),
      resize: (width, height) => widget.resize(width, height),
      getTable: () => widget.getTable(),
      instance: widget,
    };
  },
});

/**
 * Should handle more action : get_data, set_data, undo, redo
 */

Shiny.addCustomMessageHandler("tabulator_action", async function (message) {
  const { id, action, value } = message;

  const { instance: tabulatorWidget } = HTMLWidgets.find("#" + id);

  if (!tabulatorWidget) {
    console.error("Widget not found for id:", id);
    return;
  }

  switch (action) {
    case "update_data":
    case "update_where":
      await tabulatorWidget.update(action, value);
      break;
    case "add_rows":
      await tabulatorWidget.addRows(value.data, value.position);
      break;
    case "remove_rows":
      await tabulatorWidget.removeRows(value);
      break;
    case "remove_first_row":
      await tabulatorWidget.removeFirstRow();
      break;
    case "remove_last_row":
      await tabulatorWidget.removeLastRow();
      break;
    case "trigger_data":
      const data = await tabulatorWidget.getData();
      Shiny.setInputValue(id + "_data", {
        data: JSON.stringify(data),
      });
  }
});
