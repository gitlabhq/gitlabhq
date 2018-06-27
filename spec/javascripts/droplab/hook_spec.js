import Hook from '~/droplab/hook';

describe('Hook', function () {
  describe('class constructor', function () {
    beforeEach(function () {
      this.trigger = { id: 'id' };
      this.list = {};
      this.plugins = {};
      this.config = {};
      this.dropdown = {};

      this.dropdownConstructor = spyOnDependency(Hook, 'DropDown').and.returnValue(this.dropdown);

      this.hook = new Hook(this.trigger, this.list, this.plugins, this.config);
    });

    it('should set .trigger', function () {
      expect(this.hook.trigger).toBe(this.trigger);
    });

    it('should set .list', function () {
      expect(this.hook.list).toBe(this.dropdown);
    });

    it('should call DropDown constructor', function () {
      expect(this.dropdownConstructor).toHaveBeenCalledWith(this.list, this.config);
    });

    it('should set .type', function () {
      expect(this.hook.type).toBe('Hook');
    });

    it('should set .event', function () {
      expect(this.hook.event).toBe('click');
    });

    it('should set .plugins', function () {
      expect(this.hook.plugins).toBe(this.plugins);
    });

    it('should set .config', function () {
      expect(this.hook.config).toBe(this.config);
    });

    it('should set .id', function () {
      expect(this.hook.id).toBe(this.trigger.id);
    });

    describe('if config argument is undefined', function () {
      beforeEach(function () {
        this.config = undefined;

        this.hook = new Hook(this.trigger, this.list, this.plugins, this.config);
      });

      it('should set .config to an empty object', function () {
        expect(this.hook.config).toEqual({});
      });
    });

    describe('if plugins argument is undefined', function () {
      beforeEach(function () {
        this.plugins = undefined;

        this.hook = new Hook(this.trigger, this.list, this.plugins, this.config);
      });

      it('should set .plugins to an empty array', function () {
        expect(this.hook.plugins).toEqual([]);
      });
    });
  });
});
