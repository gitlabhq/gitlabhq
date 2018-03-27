import VisibilitySelect from '~/visibility_select';

(() => {
  describe('VisibilitySelect', function () {
    const lockedElement = document.createElement('div');
    lockedElement.dataset.helpBlock = 'lockedHelpBlock';

    const checkedElement = document.createElement('div');
    checkedElement.dataset.description = 'checkedDescription';

    const mockElements = {
      container: document.createElement('div'),
      select: document.createElement('div'),
      '.help-block': document.createElement('div'),
      '.js-locked': lockedElement,
      'option:checked': checkedElement,
    };

    beforeEach(function () {
      spyOn(Element.prototype, 'querySelector').and.callFake(selector => mockElements[selector]);
    });

    describe('constructor', function () {
      beforeEach(function () {
        this.visibilitySelect = new VisibilitySelect(mockElements.container);
      });

      it('sets the container member', function () {
        expect(this.visibilitySelect.container).toEqual(mockElements.container);
      });

      it('queries and sets the helpBlock member', function () {
        expect(Element.prototype.querySelector).toHaveBeenCalledWith('.help-block');
        expect(this.visibilitySelect.helpBlock).toEqual(mockElements['.help-block']);
      });

      it('queries and sets the select member', function () {
        expect(Element.prototype.querySelector).toHaveBeenCalledWith('select');
        expect(this.visibilitySelect.select).toEqual(mockElements.select);
      });

      describe('if there is no container element provided', function () {
        it('throws an error', function () {
          expect(() => new VisibilitySelect()).toThrowError('VisibilitySelect requires a container element as argument 1');
        });
      });
    });

    describe('init', function () {
      describe('if there is a select', function () {
        beforeEach(function () {
          this.visibilitySelect = new VisibilitySelect(mockElements.container);
        });

        it('calls updateHelpText', function () {
          spyOn(VisibilitySelect.prototype, 'updateHelpText');
          this.visibilitySelect.init();
          expect(this.visibilitySelect.updateHelpText).toHaveBeenCalled();
        });

        it('adds a change event listener', function () {
          spyOn(this.visibilitySelect.select, 'addEventListener');
          this.visibilitySelect.init();
          expect(this.visibilitySelect.select.addEventListener.calls.argsFor(0)).toContain('change');
        });
      });

      describe('if there is no select', function () {
        beforeEach(function () {
          mockElements.select = undefined;
          this.visibilitySelect = new VisibilitySelect(mockElements.container);
          this.visibilitySelect.init();
        });

        it('updates the helpBlock text to the locked `data-help-block` messaged', function () {
          expect(this.visibilitySelect.helpBlock.textContent)
            .toEqual(lockedElement.dataset.helpBlock);
        });

        afterEach(function () {
          mockElements.select = document.createElement('div');
        });
      });
    });

    describe('updateHelpText', function () {
      beforeEach(function () {
        this.visibilitySelect = new VisibilitySelect(mockElements.container);
        this.visibilitySelect.init();
      });

      it('updates the helpBlock text to the selected options `data-description`', function () {
        expect(this.visibilitySelect.helpBlock.textContent)
          .toEqual(checkedElement.dataset.description);
      });
    });
  });
})();
