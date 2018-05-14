import $ from 'jquery';
import NamespaceSelect from '~/namespace_select';

describe('NamespaceSelect', () => {
  beforeEach(() => {
    spyOn($.fn, 'glDropdown');
  });

  it('initializes glDropdown', () => {
    const dropdown = document.createElement('div');

    // eslint-disable-next-line no-new
    new NamespaceSelect({ dropdown });

    expect($.fn.glDropdown).toHaveBeenCalled();
  });

  describe('as input', () => {
    let glDropdownOptions;

    beforeEach(() => {
      const dropdown = document.createElement('div');
      // eslint-disable-next-line no-new
      new NamespaceSelect({ dropdown });
      glDropdownOptions = $.fn.glDropdown.calls.argsFor(0)[0];
    });

    it('prevents click events', () => {
      const dummyEvent = new Event('dummy');
      spyOn(dummyEvent, 'preventDefault');

      glDropdownOptions.clicked({ e: dummyEvent });

      expect(dummyEvent.preventDefault).toHaveBeenCalled();
    });
  });

  describe('as filter', () => {
    let glDropdownOptions;

    beforeEach(() => {
      const dropdown = document.createElement('div');
      dropdown.dataset.isFilter = 'true';
      // eslint-disable-next-line no-new
      new NamespaceSelect({ dropdown });
      glDropdownOptions = $.fn.glDropdown.calls.argsFor(0)[0];
    });

    it('does not prevent click events', () => {
      const dummyEvent = new Event('dummy');
      spyOn(dummyEvent, 'preventDefault');

      glDropdownOptions.clicked({ e: dummyEvent });

      expect(dummyEvent.preventDefault).not.toHaveBeenCalled();
    });

    it('sets URL of dropdown items', () => {
      const dummyNamespace = { id: 'eal' };

      const itemUrl = glDropdownOptions.url(dummyNamespace);

      expect(itemUrl).toContain(`namespace_id=${dummyNamespace.id}`);
    });
  });
});
