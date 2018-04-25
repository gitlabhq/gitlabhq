/* eslint-disable comma-dangle, no-param-reassign, no-unused-expressions, max-len */

import $ from 'jquery';
import GLDropdown from '~/gl_dropdown';
import '~/lib/utils/common_utils';

describe('glDropdown', function describeDropdown() {
  preloadFixtures('static/gl_dropdown.html.raw');
  loadJSONFixtures('projects.json');

  const NON_SELECTABLE_CLASSES = '.divider, .separator, .dropdown-header, .dropdown-menu-empty-item';
  const SEARCH_INPUT_SELECTOR = '.dropdown-input-field';
  const ITEM_SELECTOR = `.dropdown-content li:not(${NON_SELECTABLE_CLASSES})`;
  const FOCUSED_ITEM_SELECTOR = `${ITEM_SELECTOR} a.is-focused`;

  const ARROW_KEYS = {
    DOWN: 40,
    UP: 38,
    ENTER: 13,
    ESC: 27
  };

  let remoteCallback;

  const navigateWithKeys = function navigateWithKeys(direction, steps, cb, i) {
    i = i || 0;
    if (!i) direction = direction.toUpperCase();
    $('body').trigger({
      type: 'keydown',
      which: ARROW_KEYS[direction],
      keyCode: ARROW_KEYS[direction]
    });
    i += 1;
    if (i <= steps) {
      navigateWithKeys(direction, steps, cb, i);
    } else {
      cb();
    }
  };

  const remoteMock = function remoteMock(data, term, callback) {
    remoteCallback = callback.bind({}, data);
  };

  function initDropDown(hasRemote, isFilterable, extraOpts = {}) {
    const options = Object.assign({
      selectable: true,
      filterable: isFilterable,
      data: hasRemote ? remoteMock.bind({}, this.projectsData) : this.projectsData,
      search: {
        fields: ['name']
      },
      text: project => (project.name_with_namespace || project.name),
      id: project => project.id,
    }, extraOpts);
    this.dropdownButtonElement = $('#js-project-dropdown', this.dropdownContainerElement).glDropdown(options);
  }

  beforeEach(() => {
    loadFixtures('static/gl_dropdown.html.raw');
    this.dropdownContainerElement = $('.dropdown.inline');
    this.$dropdownMenuElement = $('.dropdown-menu', this.dropdownContainerElement);
    this.projectsData = getJSONFixture('projects.json');
  });

  afterEach(() => {
    $('body').off('keydown');
    this.dropdownContainerElement.off('keyup');
  });

  it('should open on click', () => {
    initDropDown.call(this, false);
    expect(this.dropdownContainerElement).not.toHaveClass('show');
    this.dropdownButtonElement.click();
    expect(this.dropdownContainerElement).toHaveClass('show');
  });

  it('escapes HTML as text', () => {
    this.projectsData[0].name_with_namespace = '<script>alert("testing");</script>';

    initDropDown.call(this, false);

    this.dropdownButtonElement.click();

    expect(
      $('.dropdown-content li:first-child').text(),
    ).toBe('<script>alert("testing");</script>');
  });

  it('should output HTML when highlighting', () => {
    this.projectsData[0].name_with_namespace = 'testing';
    $('.dropdown-input .dropdown-input-field').val('test');

    initDropDown.call(this, false, true, {
      highlight: true,
    });

    this.dropdownButtonElement.click();

    expect(
      $('.dropdown-content li:first-child').text(),
    ).toBe('testing');

    expect(
      $('.dropdown-content li:first-child a').html(),
    ).toBe('<b>t</b><b>e</b><b>s</b><b>t</b>ing');
  });

  describe('that is open', () => {
    beforeEach(() => {
      initDropDown.call(this, false, false);
      this.dropdownButtonElement.click();
    });

    it('should select a following item on DOWN keypress', () => {
      expect($(FOCUSED_ITEM_SELECTOR, this.$dropdownMenuElement).length).toBe(0);
      const randomIndex = (Math.floor(Math.random() * (this.projectsData.length - 1)) + 0);
      navigateWithKeys('down', randomIndex, () => {
        expect($(FOCUSED_ITEM_SELECTOR, this.$dropdownMenuElement).length).toBe(1);
        expect($(`${ITEM_SELECTOR}:eq(${randomIndex}) a`, this.$dropdownMenuElement)).toHaveClass('is-focused');
      });
    });

    it('should select a previous item on UP keypress', () => {
      expect($(FOCUSED_ITEM_SELECTOR, this.$dropdownMenuElement).length).toBe(0);
      navigateWithKeys('down', (this.projectsData.length - 1), () => {
        expect($(FOCUSED_ITEM_SELECTOR, this.$dropdownMenuElement).length).toBe(1);
        const randomIndex = (Math.floor(Math.random() * (this.projectsData.length - 2)) + 0);
        navigateWithKeys('up', randomIndex, () => {
          expect($(FOCUSED_ITEM_SELECTOR, this.$dropdownMenuElement).length).toBe(1);
          expect($(`${ITEM_SELECTOR}:eq(${((this.projectsData.length - 2) - randomIndex)}) a`, this.$dropdownMenuElement)).toHaveClass('is-focused');
        });
      });
    });

    it('should click the selected item on ENTER keypress', () => {
      expect(this.dropdownContainerElement).toHaveClass('show');
      const randomIndex = Math.floor(Math.random() * (this.projectsData.length - 1)) + 0;
      navigateWithKeys('down', randomIndex, () => {
        const visitUrl = spyOnDependency(GLDropdown, 'visitUrl').and.stub();
        navigateWithKeys('enter', null, () => {
          expect(this.dropdownContainerElement).not.toHaveClass('show');
          const link = $(`${ITEM_SELECTOR}:eq(${randomIndex}) a`, this.$dropdownMenuElement);
          expect(link).toHaveClass('is-active');
          const linkedLocation = link.attr('href');
          if (linkedLocation && linkedLocation !== '#') expect(visitUrl).toHaveBeenCalledWith(linkedLocation);
        });
      });
    });

    it('should close on ESC keypress', () => {
      expect(this.dropdownContainerElement).toHaveClass('show');
      this.dropdownContainerElement.trigger({
        type: 'keyup',
        which: ARROW_KEYS.ESC,
        keyCode: ARROW_KEYS.ESC
      });
      expect(this.dropdownContainerElement).not.toHaveClass('show');
    });
  });

  describe('opened and waiting for a remote callback', () => {
    beforeEach(() => {
      initDropDown.call(this, true, true);
      this.dropdownButtonElement.click();
    });

    it('should show loading indicator while search results are being fetched by backend', () => {
      const dropdownMenu = document.querySelector('.dropdown-menu');

      expect(dropdownMenu.className.indexOf('is-loading') !== -1).toEqual(true);
      remoteCallback();
      expect(dropdownMenu.className.indexOf('is-loading') !== -1).toEqual(false);
    });

    it('should not focus search input while remote task is not complete', () => {
      expect($(document.activeElement)).not.toEqual($(SEARCH_INPUT_SELECTOR));
      remoteCallback();
      expect($(document.activeElement)).toEqual($(SEARCH_INPUT_SELECTOR));
    });

    it('should focus search input after remote task is complete', () => {
      remoteCallback();
      expect($(document.activeElement)).toEqual($(SEARCH_INPUT_SELECTOR));
    });

    it('should focus on input when opening for the second time after transition', () => {
      remoteCallback();
      this.dropdownContainerElement.trigger({
        type: 'keyup',
        which: ARROW_KEYS.ESC,
        keyCode: ARROW_KEYS.ESC
      });
      this.dropdownButtonElement.click();
      this.dropdownContainerElement.trigger('transitionend');
      expect($(document.activeElement)).toEqual($(SEARCH_INPUT_SELECTOR));
    });
  });

  describe('input focus with array data', () => {
    it('should focus input when passing array data to drop down', () => {
      initDropDown.call(this, false, true);
      this.dropdownButtonElement.click();
      this.dropdownContainerElement.trigger('transitionend');
      expect($(document.activeElement)).toEqual($(SEARCH_INPUT_SELECTOR));
    });
  });

  it('should still have input value on close and restore', () => {
    const $searchInput = $(SEARCH_INPUT_SELECTOR);
    initDropDown.call(this, false, true);
    $searchInput
      .trigger('focus')
      .val('g')
      .trigger('input');
    expect($searchInput.val()).toEqual('g');
    this.dropdownButtonElement.trigger('hidden.bs.dropdown');
    $searchInput
      .trigger('blur')
      .trigger('focus');
    expect($searchInput.val()).toEqual('g');
  });

  describe('renderItem', () => {
    describe('without selected value', () => {
      let dropdown;

      beforeEach(() => {
        const dropdownOptions = {

        };
        const $dropdownDiv = $('<div />');
        $dropdownDiv.glDropdown(dropdownOptions);
        dropdown = $dropdownDiv.data('glDropdown');
      });

      it('marks items without ID as active', () => {
        const dummyData = { };

        const html = dropdown.renderItem(dummyData, null, null);

        const link = html.querySelector('a');
        expect(link).toHaveClass('is-active');
      });

      it('does not mark items with ID as active', () => {
        const dummyData = {
          id: 'ea'
        };

        const html = dropdown.renderItem(dummyData, null, null);

        const link = html.querySelector('a');
        expect(link).not.toHaveClass('is-active');
      });
    });
  });

  it('should keep selected item after selecting a second time', () => {
    const options = {
      isSelectable(item, $el) {
        return !$el.hasClass('is-active');
      },
      toggleLabel(item) {
        return item && item.id;
      },
    };
    initDropDown.call(this, false, false, options);
    const $item = $(`${ITEM_SELECTOR}:first() a`, this.$dropdownMenuElement);

    // select item the first time
    this.dropdownButtonElement.click();
    $item.click();
    expect($item).toHaveClass('is-active');
    // select item the second time
    this.dropdownButtonElement.click();
    $item.click();
    expect($item).toHaveClass('is-active');

    expect($('.dropdown-toggle-text')).toHaveText(this.projectsData[0].id.toString());
  });
});

