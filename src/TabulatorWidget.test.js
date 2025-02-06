import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { JSDOM } from "jsdom";
import { TabulatorWidget } from "./TabulatorWidget";
import { TabulatorExportBar } from "./TabulatorExportBar";

vi.mock("./TabulatorExportBar", () => ({
  TabulatorExportBar: vi.fn().mockImplementation(() => ({
    createExportBar: vi.fn()
  }))
}));
import { TabulatorFull as Tabulator } from "tabulator-tables";

// Setup DOM environment
const dom = new JSDOM("<!DOCTYPE html><html><body></body></html>");
global.document = dom.window.document;
global.window = dom.window;
global.Element = dom.window.Element;
global.HTMLElement = dom.window.HTMLElement;

// Mock Tabulator with row manipulation methods
vi.mock("tabulator-tables", () => ({
  TabulatorFull: vi.fn().mockImplementation(() => {
    const handlers = {};
    return {
      on: vi.fn((event, callback) => {
        handlers[event] = handlers[event] || [];
        handlers[event].push(callback);
      }),
      handlers,  // Expose handlers for testing
      destroy: vi.fn(),
      setFilter: vi.fn(),
      updateData: vi.fn(),
      replaceData: vi.fn(),
      getData: vi.fn().mockReturnValue([]),
      setData: vi.fn(),
      searchRows: vi.fn(),
      redraw: vi.fn(),
      addData: vi.fn(),
      getRow: vi.fn(),
      getRows: vi.fn(),
    };
  }),
}));

describe("TabulatorWidget Export Bar", () => {
  let widget;
  let element;

  beforeEach(() => {
    element = document.createElement("div");
    widget = new TabulatorWidget(element);
    TabulatorExportBar.mockClear();
  });

  it("should create export bar when add_export_bar is true", async () => {
    await widget.init({
      options: {
        add_export_bar: true,
        export_filename: "test_export"
      }
    });

    // Wait for tableBuilt event
    const tableBuiltCallback = widget.table.handlers.tableBuilt[0];
    tableBuiltCallback();

    expect(TabulatorExportBar).toHaveBeenCalledWith(
      widget.table,
      expect.any(HTMLElement),
      { export_filename: "test_export" }
    );
    expect(element.classList.contains("tabulator-with-exportbar")).toBe(true);
  });

  it("should not create export bar when add_export_bar is false", async () => {
    await widget.init({
      options: {
        add_export_bar: false
      }
    });

    // Wait for tableBuilt event
    const tableBuiltCallback = widget.table.handlers.tableBuilt[0];
    tableBuiltCallback();

    expect(TabulatorExportBar).not.toHaveBeenCalled();
    expect(element.classList.contains("tabulator-with-exportbar")).toBe(false);
  });

  it("should use default filename when export_filename is not provided", async () => {
    await widget.init({
      options: {
        add_export_bar: true
      }
    });

    // Wait for tableBuilt event
    const tableBuiltCallback = widget.table.handlers.tableBuilt[0];
    tableBuiltCallback();

    expect(TabulatorExportBar).toHaveBeenCalledWith(
      widget.table,
      expect.any(HTMLElement),
      { export_filename: "data" }
    );
  });
});

describe("TabulatorWidget Row Manipulation", () => {
  let widget;
  let element;
  let callbacks;

  beforeEach(async () => {
    element = document.createElement("div");
    document.body.appendChild(element);
    callbacks = new Map([["rowClick", vi.fn()]]);
    widget = new TabulatorWidget(element, callbacks);
    await widget.init({ options: { data: [] } });
  });

  afterEach(() => {
    if (widget && widget.table) {
      widget.destroy();
    }
    if (element && element.parentNode) {
      element.parentNode.removeChild(element);
    }
    vi.clearAllMocks();
  });

  // Test addRows functionality
  describe("addRows", () => {
    it("should add rows at the bottom by default", async () => {
      const newData = [
        { id: 1, name: "John" },
        { id: 2, name: "Jane" },
      ];

      await widget.addRows(newData);

      expect(widget.table.addData).toHaveBeenCalledWith(newData, false);
      expect(widget.table.getData).toHaveBeenCalled();
      expect(widget.table.setData).toHaveBeenCalled();
    });

    it("should add rows at the top when specified", async () => {
      const newData = [{ id: 1, name: "John" }];

      await widget.addRows(newData, "top");

      expect(widget.table.addData).toHaveBeenCalledWith(newData, true);
    });

    it("should handle array and object inputs correctly", async () => {
      const arrayData = [{ id: 1, name: "John" }];
      const objectData = {
        id: [1],
        name: ["John"],
      };

      await widget.addRows(arrayData);
      expect(widget.table.addData).toHaveBeenCalledWith(arrayData, false);

      await widget.addRows(objectData);
      expect(widget.table.addData).toHaveBeenCalledWith(
        [{ id: 1, name: "John" }],
        false
      );
    });

    it("should handle errors gracefully", async () => {
      const consoleSpy = vi
        .spyOn(console, "error")
        .mockImplementation(() => {});
      widget.table.addData.mockRejectedValueOnce(new Error("Add data failed"));

      await widget.addRows([{ id: 1 }]);

      expect(consoleSpy).toHaveBeenCalledWith(
        "Error adding rows:",
        expect.any(Error)
      );
      consoleSpy.mockRestore();
    });
  });

  // Test removeRows functionality
  describe("removeRows", () => {
    it("should remove specified rows by ID", async () => {
      const mockRow1 = { delete: vi.fn() };
      const mockRow2 = { delete: vi.fn() };

      widget.table.getRow
        .mockReturnValueOnce(mockRow1)
        .mockReturnValueOnce(mockRow2);

      await widget.removeRows(["row1", "row2"]);

      expect(widget.table.getRow).toHaveBeenCalledTimes(2);
      expect(mockRow1.delete).toHaveBeenCalled();
      expect(mockRow2.delete).toHaveBeenCalled();
      expect(widget.table.getData).toHaveBeenCalled();
      expect(widget.table.setData).toHaveBeenCalled();
    });

    it("should handle non-existent row IDs gracefully", async () => {
      widget.table.getRow.mockReturnValue(null);

      await widget.removeRows(["nonexistent"]);

      expect(widget.table.getData).toHaveBeenCalled();
      expect(widget.table.setData).toHaveBeenCalled();
    });
  });

  // Test removeFirstRow functionality
  describe("removeFirstRow", () => {
    it("should remove the first row", async () => {
      const mockFirstRow = { delete: vi.fn() };
      widget.table.getRows.mockReturnValue([mockFirstRow]);

      await widget.removeFirstRow();

      expect(widget.table.getRows).toHaveBeenCalled();
      expect(mockFirstRow.delete).toHaveBeenCalled();
      expect(widget.table.getData).toHaveBeenCalled();
      expect(widget.table.setData).toHaveBeenCalled();
    });

    it("should handle empty table gracefully", async () => {
      widget.table.getRows.mockReturnValue([]);

      await widget.removeFirstRow();

      expect(widget.table.getData).not.toHaveBeenCalled();
      expect(widget.table.setData).not.toHaveBeenCalled();
    });
  });

  // Test removeLastRow functionality
  describe("removeLastRow", () => {
    it("should remove the last row", async () => {
      const mockLastRow = { delete: vi.fn() };
      widget.table.getRows.mockReturnValue([{}, {}, mockLastRow]);

      await widget.removeLastRow();

      expect(widget.table.getRows).toHaveBeenCalled();
      expect(mockLastRow.delete).toHaveBeenCalled();
      expect(widget.table.getData).toHaveBeenCalled();
      expect(widget.table.setData).toHaveBeenCalled();
    });

    it("should handle empty table gracefully", async () => {
      widget.table.getRows.mockReturnValue([]);

      await widget.removeLastRow();

      expect(widget.table.getData).not.toHaveBeenCalled();
      expect(widget.table.setData).not.toHaveBeenCalled();
    });
  });

  // Test error handling for all methods when table is not initialized
  describe("error handling without table", () => {
    beforeEach(() => {
      widget.table = null;
    });

    it("should handle addRows when table is not initialized", async () => {
      const consoleSpy = vi
        .spyOn(console, "error")
        .mockImplementation(() => {});

      await widget.addRows([{ id: 1 }]);

      expect(consoleSpy).toHaveBeenCalledWith("Table instance not found");
      consoleSpy.mockRestore();
    });

    it("should handle removeRows when table is not initialized", async () => {
      const consoleSpy = vi
        .spyOn(console, "error")
        .mockImplementation(() => {});

      await widget.removeRows(["row1"]);

      expect(consoleSpy).toHaveBeenCalledWith("Table instance not found");
      consoleSpy.mockRestore();
    });

    it("should handle removeFirstRow when table is not initialized", async () => {
      const consoleSpy = vi
        .spyOn(console, "error")
        .mockImplementation(() => {});

      await widget.removeFirstRow();

      expect(consoleSpy).toHaveBeenCalledWith("Table instance not found");
      consoleSpy.mockRestore();
    });

    it("should handle removeLastRow when table is not initialized", async () => {
      const consoleSpy = vi
        .spyOn(console, "error")
        .mockImplementation(() => {});

      await widget.removeLastRow();

      expect(consoleSpy).toHaveBeenCalledWith("Table instance not found");
      consoleSpy.mockRestore();
    });
  });
});
