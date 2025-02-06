import { describe, it, expect, vi, beforeEach } from "vitest";
import { TabulatorExportBar } from "./TabulatorExportBar";

describe("TabulatorExportBar", () => {
  let mockTable;
  let mockElement;
  let exportBar;

  beforeEach(() => {
    mockTable = {
      download: vi.fn(),
    };
    mockElement = document.createElement("div");
    exportBar = new TabulatorExportBar(mockTable, mockElement, {
      export_filename: "test_data",
    });
  });

  it("should create export bar with correct class", () => {
    exportBar.createExportBar();
    expect(mockElement.classList.contains("tabulator-export-bar")).toBe(true);
  });

  it("should create export controls with two buttons", () => {
    exportBar.createExportBar();
    const buttons = mockElement.querySelectorAll(".link-button");
    expect(buttons.length).toBe(2);
    expect(buttons[0].textContent).toBe("[Download CSV]");
    expect(buttons[1].textContent).toBe("[Download JSON]");
  });

  it("should use default filename when not provided", () => {
    exportBar = new TabulatorExportBar(mockTable, mockElement);
    exportBar.createExportBar();
    const csvButton = mockElement.querySelector(".link-button");
    csvButton.click();
    expect(mockTable.download).toHaveBeenCalledWith("csv", "data.csv");
  });

  it("should use custom filename when provided", () => {
    exportBar.createExportBar();
    const csvButton = mockElement.querySelector(".link-button");
    csvButton.click();
    expect(mockTable.download).toHaveBeenCalledWith("csv", "test_data.csv");
  });

  it("should trigger CSV download with correct filename", () => {
    exportBar.createExportBar();
    const csvButton = mockElement.querySelector(".link-button");
    csvButton.click();
    expect(mockTable.download).toHaveBeenCalledWith("csv", "test_data.csv");
  });

  it("should trigger JSON download with correct filename", () => {
    exportBar.createExportBar();
    const buttons = mockElement.querySelectorAll(".link-button");
    const jsonButton = buttons[1];
    jsonButton.click();
    expect(mockTable.download).toHaveBeenCalledWith("json", "test_data.json");
  });
});
