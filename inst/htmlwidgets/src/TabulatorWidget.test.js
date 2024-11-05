import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { JSDOM } from 'jsdom';
import { TabulatorWidget } from './TabulatorWidget';
import { TabulatorFull as Tabulator } from 'tabulator-tables';

// Setup DOM environment
const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>');
global.document = dom.window.document;
global.window = dom.window;
global.Element = dom.window.Element;
global.HTMLElement = dom.window.HTMLElement;

// Mock Tabulator
vi.mock('tabulator-tables', () => ({
  TabulatorFull: vi.fn().mockImplementation(() => ({
    on: vi.fn(),
    destroy: vi.fn(),
    setFilter: vi.fn(),
    updateData: vi.fn(),
    getData: vi.fn().mockReturnValue([]),
    setData: vi.fn(),
    searchRows: vi.fn(),
    redraw: vi.fn()
  }))
}));

describe('TabulatorWidget', () => {
  let widget;
  let element;
  let callbacks;

  beforeEach(() => {
    // Setup DOM element and callbacks
    element = document.createElement('div');
    document.body.appendChild(element);
    callbacks = new Map([['rowClick', vi.fn()]]);
    widget = new TabulatorWidget(element, callbacks);
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

  // Test 1: Initialization and renderValue
  it('should properly initialize and render the table with correct options', () => {
    const options = {
      data: [{ id: 1, name: 'Test' }],
      add_select_column: true,
      columns: [{ title: 'Name', field: 'name' }]
    };

    widget.renderValue({ options });

    expect(Tabulator).toHaveBeenCalledWith(element, expect.objectContaining({
      data: [{ id: 1, name: 'Test' }],
      columns: [
        {
          formatter: 'rowSelection',
          titleFormatter: 'rowSelection',
          headerSort: false,
          width: 50,
          headerFilter: false,
          frozen: true,
          headerTooltip: false,
          tooltip: false,
          resizable: false
        },
        { title: 'Name', field: 'name' }
      ]
    }));
    expect(widget.table).toBeTruthy();
  });

  // Test 2: Data format conversion
  it('should correctly format table data from object of arrays to array of objects', () => {
    const inputData = {
      id: [1, 2, 3],
      name: ['Alice', 'Bob', 'Charlie']
    };

    const expectedOutput = [
      { id: 1, name: 'Alice' },
      { id: 2, name: 'Bob' },
      { id: 3, name: 'Charlie' }
    ];

    const result = widget.formatTable(inputData);
    expect(result).toEqual(expectedOutput);
  });

  // Test 3: Update functionality
  it('should handle data updates correctly', async () => {
    widget.renderValue({ options: { data: [] } });

    const updatePayload = {
      data: [{ id: 1, name: 'New Data' }],
      chunk: 1,
      total_chunks: 1
    };

    await widget.update('update_data', updatePayload);

    expect(widget.table.updateData).toHaveBeenCalledWith([{ id: 1, name: 'New Data' }]);
    expect(widget.table.setData).toHaveBeenCalled();
  });

  // Test 4: Error handling
  it('should handle errors gracefully during table creation', () => {
    const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
    Tabulator.mockImplementationOnce(() => {
      throw new Error('Tabulator initialization failed');
    });

    widget.renderValue({ options: {} });

    expect(consoleSpy).toHaveBeenCalledWith(
      'Error creating Tabulator instance:',
      expect.any(Error)
    );
    expect(widget.table).toBeFalsy();
    consoleSpy.mockRestore();
  });

  // Test 5: Complex updateWhere functionality
  it('should correctly handle updateWhere operations with chunking', async () => {
    widget.renderValue({ options: { data: [] } });
    
    const mockMatchingRows = [
      { getData: () => ({ id: 1, value: 'old' }) },
      { getData: () => ({ id: 2, value: 'old' }) },
      { getData: () => ({ id: 3, value: 'old' }) }
    ];

    widget.table.searchRows.mockReturnValue(mockMatchingRows);

    await widget.updateWhere({
      col: 'value',
      value: 'new',
      whereCol: 'id',
      whereValue: [1, 2, 3],
      operator: 'in',
      chunk_size: 2
    });

    // Should have called updateData twice due to chunk_size of 2
    expect(widget.table.updateData).toHaveBeenCalledTimes(2);
    expect(widget.table.updateData).toHaveBeenNthCalledWith(1, [
      { id: 1, value: 'new' },
      { id: 2, value: 'new' }
    ]);
    expect(widget.table.updateData).toHaveBeenNthCalledWith(2, [
      { id: 3, value: 'new' }
    ]);
  });
});
