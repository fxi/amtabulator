import { TabulatorWidget } from "./TabulatorWidget";

HTMLWidgets.widget({
  name: "tabulator",
  type: "output",
  factory: function (el) {
    const callbacks = [
      [
        "dataChanged",
        function (data) {
          Shiny.setInputValue(el.id + "_data_changed", {
            data: JSON.stringify(data),
          });
        },
      ],
      [
        "rowSelectionChanged",
        function (data) {
          Shiny.setInputValue(el.id + "_data_selection", {
            data: JSON.stringify(data),
          });
        },
      ],
      [
        "cellEdited",
        function (cell) {
          Shiny.setInputValue(el.id + "_cell_edit", {
            row: cell.getRow().getData(),
            column: cell.getColumn().getField(),
            oldValue: cell.getOldValue(),
            newValue: cell.getValue(),
          });
        },
      ],
    ];

    const widget = new TabulatorWidget(el, callbacks);

    return {
      renderValue: (x) => widget.renderValue(x),
      resize: (width, height) => widget.resize(width, height),
      getTable: () => widget.getTable(),
      instance: widget,
    };
  },
});

Shiny.addCustomMessageHandler("tabulator-update", async function (message) {
  const { id, action, value } = message;
  const { instance: tabulatorWidget } = HTMLWidgets.find("#" + id);

  if (!tabulatorWidget) {
    console.error("Widget not found for id:", id);
    return;
  }

  await tabulatorWidget.update(action, value);
});
