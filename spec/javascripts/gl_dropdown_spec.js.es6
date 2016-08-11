/*= require jquery */
/*= require gl_dropdown */
/*= require turbolinks */
/*= require lib/utils/common_utils */
/*= require lib/utils/type_utility */

(() => {
  const NON_SELECTABLE_CLASSES = '.divider, .separator, .dropdown-header, .dropdown-menu-empty-link';
  const ITEM_SELECTOR = `.dropdown-content li:not(${NON_SELECTABLE_CLASSES})`;
  const FOCUSED_ITEM_SELECTOR = `${ITEM_SELECTOR} a.is-focused`;

  const ARROW_KEYS = {
    DOWN: 40,
    UP: 38,
    ENTER: 13,
    ESC: 27
  };

  let navigateWithKeys = function navigateWithKeys(direction, steps, cb, i) {
    i = i || 0;
    if (!i) direction = direction.toUpperCase();
    $('body').trigger({
      type: 'keydown',
      which: ARROW_KEYS[direction],
      keyCode: ARROW_KEYS[direction]
    });
    i++;
    if (i <= steps) {
      navigateWithKeys(direction, steps, cb, i);
    } else {
      cb();
    }
  };

  describe('Dropdown', function describeDropdown() {
    fixture.preload('gl_dropdown.html');
    fixture.preload('projects.json');

    beforeEach(() => {
      fixture.load('gl_dropdown.html');
      this.dropdownContainerElement = $('.dropdown.inline');
      this.dropdownMenuElement = $('.dropdown-menu', this.dropdownContainerElement);
      this.projectsData = fixture.load('projects.json')[0];
      this.dropdownButtonElement = $('#js-project-dropdown', this.dropdownContainerElement).glDropdown({
        selectable: true,
        data: this.projectsData,
        text: (project) => {
          (project.name_with_namespace || project.name);
        },
        id: (project) => {
          project.id;
        }
      });
    });

    afterEach(() => {
      $('body').unbind('keydown');
      this.dropdownContainerElement.unbind('keyup');
    });

    it('should open on click', () => {
      expect(this.dropdownContainerElement).not.toHaveClass('open');
      this.dropdownButtonElement.click();
      expect(this.dropdownContainerElement).toHaveClass('open');
    });

    describe('that is open', () => {
      beforeEach(() => {
        this.dropdownButtonElement.click();
      });

      it('should select a following item on DOWN keypress', () => {
        expect($(FOCUSED_ITEM_SELECTOR, this.dropdownMenuElement).length).toBe(0);
        let randomIndex = (Math.floor(Math.random() * (this.projectsData.length - 1)) + 0);
        navigateWithKeys('down', randomIndex, () => {
          expect($(FOCUSED_ITEM_SELECTOR, this.dropdownMenuElement).length).toBe(1);
          expect($(`${ITEM_SELECTOR}:eq(${randomIndex}) a`, this.dropdownMenuElement)).toHaveClass('is-focused');
        });
      });

      it('should select a previous item on UP keypress', () => {
        expect($(FOCUSED_ITEM_SELECTOR, this.dropdownMenuElement).length).toBe(0);
        navigateWithKeys('down', (this.projectsData.length - 1), () => {
          expect($(FOCUSED_ITEM_SELECTOR, this.dropdownMenuElement).length).toBe(1);
          let randomIndex = (Math.floor(Math.random() * (this.projectsData.length - 2)) + 0);
          navigateWithKeys('up', randomIndex, () => {
            expect($(FOCUSED_ITEM_SELECTOR, this.dropdownMenuElement).length).toBe(1);
            expect($(`${ITEM_SELECTOR}:eq(${((this.projectsData.length - 2) - randomIndex)}) a`, this.dropdownMenuElement)).toHaveClass('is-focused');
          });
        });
      });

      it('should click the selected item on ENTER keypress', () => {
        expect(this.dropdownContainerElement).toHaveClass('open')
        let randomIndex = Math.floor(Math.random() * (this.projectsData.length - 1)) + 0
        navigateWithKeys('down', randomIndex, () => {
          spyOn(Turbolinks, 'visit').and.stub();
          navigateWithKeys('enter', null, () => {
            expect(this.dropdownContainerElement).not.toHaveClass('open');
            let link = $(`${ITEM_SELECTOR}:eq(${randomIndex}) a`, this.dropdownMenuElement);
            expect(link).toHaveClass('is-active');
            let linkedLocation = link.attr('href');
            if (linkedLocation && linkedLocation !== '#') expect(Turbolinks.visit).toHaveBeenCalledWith(linkedLocation);
          });
        });
      });

      it('should close on ESC keypress', () => {
        expect(this.dropdownContainerElement).toHaveClass('open');
        this.dropdownContainerElement.trigger({
          type: 'keyup',
          which: ARROW_KEYS.ESC,
          keyCode: ARROW_KEYS.ESC
        });
        expect(this.dropdownContainerElement).not.toHaveClass('open');
      });
    });
  });
})();
