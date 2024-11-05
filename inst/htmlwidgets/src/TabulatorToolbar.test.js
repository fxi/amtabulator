import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { JSDOM } from 'jsdom';
import { TabulatorToolbar } from './TabulatorToolbar';

// Setup DOM environment
const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>');
global.document = dom.window.document;
global.window = dom.window;

describe('TabulatorToolbar', () => {
  let toolbar;
  let mockTable;
  let targetElement;

  // Mock column definition
  const mockColumns = [
    {
      getField: () => 'name',
      getDefinition: () => ({ title: 'Name' })
    },
    {
      getField: () => 'age',
      getDefinition: () => ({ title: 'Age' })
    }
  ];

  // Mock data
  const mockData = [
    { name: 'John', age: 30 },
    { name: 'Jane', age: 25 }
  ];

  beforeEach(() => {
    // Create target element
    targetElement = document.createElement('div');
    document.body.appendChild(targetElement);

    // Create mock table
    mockTable = {
      getColumns: vi.fn().mockReturnValue(mockColumns),
      getData: vi.fn().mockReturnValue(mockData),
      getColumn: vi.fn().mockImplementation((field) => 
        mockColumns.find(col => col.getField() === field)
      ),
      searchRows: vi.fn().mockReturnValue([
        { select: vi.fn(), deselect: vi.fn() }
      ]),
      selectRow: vi.fn(),
      deselectRow: vi.fn()
    };

    toolbar = new TabulatorToolbar(mockTable, targetElement);
  });

  afterEach(() => {
    if (targetElement.parentNode) {
      targetElement.parentNode.removeChild(targetElement);
    }
    vi.clearAllMocks();
  });

  // Test 1: Toolbar Initialization
  it('should properly initialize toolbar with all components', () => {
    toolbar.createToolbar();

    // Check if all main elements are created
    expect(targetElement.querySelector('.tabulator-toolbar')).toBeTruthy();
    expect(targetElement.querySelector('.selection-controls')).toBeTruthy();
    expect(targetElement.querySelector('.column-selector')).toBeTruthy();
    expect(targetElement.querySelector('.operator-selector')).toBeTruthy();
    expect(targetElement.querySelector('.value-input')).toBeTruthy();
    expect(targetElement.querySelector('.action-buttons')).toBeTruthy();

    // Verify column selector options
    const columnSelector = targetElement.querySelector('.column-selector');
    expect(columnSelector.options.length).toBe(3); // Default option + 2 columns
    expect(columnSelector.options[1].value).toBe('name');
    expect(columnSelector.options[2].value).toBe('age');
  });

  // Test 2: Selection Controls
  it('should handle select all and none operations', () => {
    toolbar.createToolbar();

    // Find and click the [All] button
    const allButton = Array.from(targetElement.querySelectorAll('a'))
      .find(a => a.textContent === '[All]');
    allButton.click();
    expect(mockTable.selectRow).toHaveBeenCalled();

    // Find and click the [None] button
    const noneButton = Array.from(targetElement.querySelectorAll('a'))
      .find(a => a.textContent === '[None]');
    noneButton.click();
    expect(mockTable.deselectRow).toHaveBeenCalled();
  });

  // Test 3: Column Selection and Input Type Changes
  it('should update operators and input type when column selection changes', () => {
    toolbar.createToolbar();
    const columnSelector = targetElement.querySelector('.column-selector');
    const operatorSelector = targetElement.querySelector('.operator-selector');

    // Mock numerical column data
    mockTable.getData.mockReturnValueOnce([{ age: 25 }]);
    
    // Simulate selecting the age column
    columnSelector.value = 'age';
    columnSelector.dispatchEvent(new Event('change'));

    // Check if operators were updated for numerical type
    const operators = Array.from(operatorSelector.options).map(opt => opt.value).filter(Boolean);
    expect(operators).toEqual(['=', '!=', '>', '<', '>=', '<=']);

    // Check if input type was changed to number
    const valueInput = targetElement.querySelector('.value-input');
    expect(valueInput.type).toBe('number');
  });

  // Test 4: Apply Selection Functionality
  it('should apply selection based on criteria', async () => {
    toolbar.createToolbar();

    // Mock data for this specific test
    const mockSelectedRows = [{ select: vi.fn(), deselect: vi.fn() }];
    mockTable.searchRows.mockReturnValue(mockSelectedRows);
    
    // Set up selection criteria
    const columnSelector = targetElement.querySelector('.column-selector');
    columnSelector.value = 'name';
    columnSelector.dispatchEvent(new Event('change'));

    const operatorSelector = targetElement.querySelector('.operator-selector');
    operatorSelector.value = '=';

    const valueInput = targetElement.querySelector('.value-input');
    valueInput.value = 'John';
    valueInput.dispatchEvent(new Event('input'));

    // Click the [Select] button
    const selectButton = Array.from(targetElement.querySelectorAll('a'))
      .find(a => a.textContent === '[Select]');
    selectButton.click();

    // Verify the correct arguments were passed to searchRows
    expect(mockTable.searchRows).toHaveBeenCalledWith('name', '=', 'John');
    expect(mockSelectedRows[0].select).toHaveBeenCalled();
  });

  // Test 5: Dynamic Input Creation for String Columns
  it('should create appropriate input type based on column data', () => {
    // Setup mock data with specific values
    const mockStringData = [
      { name: 'A' },
      { name: 'B' },
      { name: 'C' }
    ];
    
    // Update mock for this specific test
    mockTable.getData.mockReturnValue(mockStringData);
    
    toolbar.createToolbar();

    // Select the name column
    const columnSelector = targetElement.querySelector('.column-selector');
    columnSelector.value = 'name';
    columnSelector.dispatchEvent(new Event('change'));

    // Check if a select input was created
    const valueInput = targetElement.querySelector('.value-input');
    expect(valueInput.tagName.toLowerCase()).toBe('select');
    
    // Verify options are properly sorted and match the mock data
    const options = Array.from(valueInput.options)
      .map(opt => opt.value)
      .filter(Boolean); // Remove empty/default option
      
    expect(options).toEqual(['A', 'B', 'C']);
  });
});
