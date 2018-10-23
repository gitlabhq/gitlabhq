import InputSetter from '~/droplab/plugins/input_setter';

describe('InputSetter', function() {
  describe('init', function() {
    beforeEach(function() {
      this.config = { InputSetter: {} };
      this.hook = { config: this.config };
      this.inputSetter = jasmine.createSpyObj('inputSetter', ['addEvents']);

      InputSetter.init.call(this.inputSetter, this.hook);
    });

    it('should set .hook', function() {
      expect(this.inputSetter.hook).toBe(this.hook);
    });

    it('should set .config', function() {
      expect(this.inputSetter.config).toBe(this.config.InputSetter);
    });

    it('should set .eventWrapper', function() {
      expect(this.inputSetter.eventWrapper).toEqual({});
    });

    it('should call .addEvents', function() {
      expect(this.inputSetter.addEvents).toHaveBeenCalled();
    });

    describe('if config.InputSetter is not set', function() {
      beforeEach(function() {
        this.config = { InputSetter: undefined };
        this.hook = { config: this.config };

        InputSetter.init.call(this.inputSetter, this.hook);
      });

      it('should set .config to an empty object', function() {
        expect(this.inputSetter.config).toEqual({});
      });

      it('should set hook.config to an empty object', function() {
        expect(this.hook.config.InputSetter).toEqual({});
      });
    });
  });

  describe('addEvents', function() {
    beforeEach(function() {
      this.hook = { list: { list: jasmine.createSpyObj('list', ['addEventListener']) } };
      this.inputSetter = { eventWrapper: {}, hook: this.hook, setInputs: () => {} };

      InputSetter.addEvents.call(this.inputSetter);
    });

    it('should set .eventWrapper.setInputs', function() {
      expect(this.inputSetter.eventWrapper.setInputs).toEqual(jasmine.any(Function));
    });

    it('should call .addEventListener', function() {
      expect(this.hook.list.list.addEventListener).toHaveBeenCalledWith(
        'click.dl',
        this.inputSetter.eventWrapper.setInputs,
      );
    });
  });

  describe('removeEvents', function() {
    beforeEach(function() {
      this.hook = { list: { list: jasmine.createSpyObj('list', ['removeEventListener']) } };
      this.eventWrapper = jasmine.createSpyObj('eventWrapper', ['setInputs']);
      this.inputSetter = { eventWrapper: this.eventWrapper, hook: this.hook };

      InputSetter.removeEvents.call(this.inputSetter);
    });

    it('should call .removeEventListener', function() {
      expect(this.hook.list.list.removeEventListener).toHaveBeenCalledWith(
        'click.dl',
        this.eventWrapper.setInputs,
      );
    });
  });

  describe('setInputs', function() {
    beforeEach(function() {
      this.event = { detail: { selected: {} } };
      this.config = [0, 1];
      this.inputSetter = { config: this.config, setInput: () => {} };

      spyOn(this.inputSetter, 'setInput');

      InputSetter.setInputs.call(this.inputSetter, this.event);
    });

    it('should call .setInput for each config element', function() {
      const allArgs = this.inputSetter.setInput.calls.allArgs();

      expect(allArgs.length).toEqual(2);

      allArgs.forEach((args, i) => {
        expect(args[0]).toBe(this.config[i]);
        expect(args[1]).toBe(this.event.detail.selected);
      });
    });

    describe('if config isnt an array', function() {
      beforeEach(function() {
        this.inputSetter = { config: {}, setInput: () => {} };

        InputSetter.setInputs.call(this.inputSetter, this.event);
      });

      it('should set .config to an array with .config as the first element', function() {
        expect(this.inputSetter.config).toEqual([{}]);
      });
    });
  });

  describe('setInput', function() {
    beforeEach(function() {
      this.selectedItem = { getAttribute: () => {} };
      this.input = { value: 'oldValue', tagName: 'INPUT', hasAttribute: () => {} };
      this.config = { valueAttribute: {}, input: this.input };
      this.inputSetter = { hook: { trigger: {} } };
      this.newValue = 'newValue';

      spyOn(this.selectedItem, 'getAttribute').and.returnValue(this.newValue);
      spyOn(this.input, 'hasAttribute').and.returnValue(false);

      InputSetter.setInput.call(this.inputSetter, this.config, this.selectedItem);
    });

    it('should call .getAttribute', function() {
      expect(this.selectedItem.getAttribute).toHaveBeenCalledWith(this.config.valueAttribute);
    });

    it('should call .hasAttribute', function() {
      expect(this.input.hasAttribute).toHaveBeenCalledWith(undefined);
    });

    it('should set the value of the input', function() {
      expect(this.input.value).toBe(this.newValue);
    });

    describe('if no config.input is provided', function() {
      beforeEach(function() {
        this.config = { valueAttribute: {} };
        this.trigger = { value: 'oldValue', tagName: 'INPUT', hasAttribute: () => {} };
        this.inputSetter = { hook: { trigger: this.trigger } };

        InputSetter.setInput.call(this.inputSetter, this.config, this.selectedItem);
      });

      it('should set the value of the hook.trigger', function() {
        expect(this.trigger.value).toBe(this.newValue);
      });
    });

    describe('if the input tag is not INPUT', function() {
      beforeEach(function() {
        this.input = { textContent: 'oldValue', tagName: 'SPAN', hasAttribute: () => {} };
        this.config = { valueAttribute: {}, input: this.input };

        InputSetter.setInput.call(this.inputSetter, this.config, this.selectedItem);
      });

      it('should set the textContent of the input', function() {
        expect(this.input.textContent).toBe(this.newValue);
      });
    });

    describe('if there is an inputAttribute', function() {
      beforeEach(function() {
        this.selectedItem = { getAttribute: () => {} };
        this.input = { id: 'oldValue', hasAttribute: () => {}, setAttribute: () => {} };
        this.inputSetter = { hook: { trigger: {} } };
        this.newValue = 'newValue';
        this.inputAttribute = 'id';
        this.config = {
          valueAttribute: {},
          input: this.input,
          inputAttribute: this.inputAttribute,
        };

        spyOn(this.selectedItem, 'getAttribute').and.returnValue(this.newValue);
        spyOn(this.input, 'hasAttribute').and.returnValue(true);
        spyOn(this.input, 'setAttribute');

        InputSetter.setInput.call(this.inputSetter, this.config, this.selectedItem);
      });

      it('should call setAttribute', function() {
        expect(this.input.setAttribute).toHaveBeenCalledWith(this.inputAttribute, this.newValue);
      });

      it('should not set the value or textContent of the input', function() {
        expect(this.input.value).not.toBe('newValue');
        expect(this.input.textContent).not.toBe('newValue');
      });
    });
  });

  describe('destroy', function() {
    beforeEach(function() {
      this.inputSetter = jasmine.createSpyObj('inputSetter', ['removeEvents']);

      InputSetter.destroy.call(this.inputSetter);
    });

    it('should call .removeEvents', function() {
      expect(this.inputSetter.removeEvents).toHaveBeenCalled();
    });
  });
});
