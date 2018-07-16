import $ from 'jquery';
import _ from 'underscore';
import Autosave from '~/autosave';
import AccessorUtilities from '~/lib/utils/accessor';

describe('Autosave', () => {
  let autosave;
  const field = $('<textarea></textarea>');
  const key = 'key';

  describe('class constructor', () => {
    beforeEach(() => {
      spyOn(AccessorUtilities, 'isLocalStorageAccessSafe').and.returnValue(true);
      spyOn(_, 'debounce');
      spyOn(Autosave.prototype, 'save');
      spyOn(Autosave.prototype, 'restore');
      autosave = new Autosave(field, key);
    });

    it('should debounce the input handler', () => {
      expect(_.debounce).toHaveBeenCalled();
      expect(autosave.save).not.toHaveBeenCalled();

      const [cb, timer] = _.debounce.calls.argsFor(0);
      cb(); // execute debounced callback

      expect(timer).toEqual(Autosave.DEBOUNCE_TIMER);
      expect(autosave.save).toHaveBeenCalled();
    });

    it('should set .isLocalStorageAvailable', () => {
      expect(AccessorUtilities.isLocalStorageAccessSafe).toHaveBeenCalled();
      expect(autosave.isLocalStorageAvailable).toBe(true);
    });
  });

  describe('restore', () => {
    beforeEach(() => {
      autosave = {
        field,
        key,
      };

      spyOn(window.localStorage, 'getItem');
    });

    describe('if .isLocalStorageAvailable is `false`', () => {
      beforeEach(() => {
        autosave.isLocalStorageAvailable = false;

        Autosave.prototype.restore.call(autosave);
      });

      it('should not call .getItem', () => {
        expect(window.localStorage.getItem).not.toHaveBeenCalled();
      });
    });

    describe('if .isLocalStorageAvailable is `true`', () => {
      beforeEach(() => {
        autosave.isLocalStorageAvailable = true;
      });

      it('should call .getItem', () => {
        Autosave.prototype.restore.call(autosave);

        expect(window.localStorage.getItem).toHaveBeenCalledWith(key);
      });

      it('triggers jquery event', () => {
        spyOn(autosave.field, 'trigger').and.callThrough();

        Autosave.prototype.restore.call(autosave);

        expect(field.trigger).toHaveBeenCalled();
      });

      it('triggers native event', done => {
        autosave.field.get(0).addEventListener('change', () => {
          done();
        });

        Autosave.prototype.restore.call(autosave);
      });
    });

    describe('if field gets deleted from DOM', () => {
      beforeEach(() => {
        autosave.field = $('.not-a-real-element');
      });

      it('does not trigger event', () => {
        spyOn(field, 'trigger').and.callThrough();

        expect(field.trigger).not.toHaveBeenCalled();
      });
    });
  });

  describe('save', () => {
    beforeEach(() => {
      autosave = jasmine.createSpyObj('autosave', ['reset']);
      autosave.field = field;
      field.val('value');

      spyOn(window.localStorage, 'setItem');
    });

    describe('if .isLocalStorageAvailable is `false`', () => {
      beforeEach(() => {
        autosave.isLocalStorageAvailable = false;

        Autosave.prototype.save.call(autosave);
      });

      it('should not call .setItem', () => {
        expect(window.localStorage.setItem).not.toHaveBeenCalled();
      });
    });

    describe('if .isLocalStorageAvailable is `true`', () => {
      beforeEach(() => {
        autosave.isLocalStorageAvailable = true;

        Autosave.prototype.save.call(autosave);
      });

      it('should call .setItem', () => {
        expect(window.localStorage.setItem).toHaveBeenCalled();
      });
    });
  });

  describe('reset', () => {
    beforeEach(() => {
      autosave = {
        key,
      };

      spyOn(window.localStorage, 'removeItem');
    });

    describe('if .isLocalStorageAvailable is `false`', () => {
      beforeEach(() => {
        autosave.isLocalStorageAvailable = false;

        Autosave.prototype.reset.call(autosave);
      });

      it('should not call .removeItem', () => {
        expect(window.localStorage.removeItem).not.toHaveBeenCalled();
      });
    });

    describe('if .isLocalStorageAvailable is `true`', () => {
      beforeEach(() => {
        autosave.isLocalStorageAvailable = true;

        Autosave.prototype.reset.call(autosave);
      });

      it('should call .removeItem', () => {
        expect(window.localStorage.removeItem).toHaveBeenCalledWith(key);
      });
    });
  });
});
