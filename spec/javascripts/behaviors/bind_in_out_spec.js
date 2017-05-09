import BindInOut from '~/behaviors/bind_in_out';
import ClassSpecHelper from '../helpers/class_spec_helper';

describe('BindInOut', function () {
  describe('constructor', function () {
    beforeEach(function () {
      this.in = {};
      this.out = {};

      this.bindInOut = new BindInOut(this.in, this.out);
    });

    it('should set .in', function () {
      expect(this.bindInOut.in).toBe(this.in);
    });

    it('should set .out', function () {
      expect(this.bindInOut.out).toBe(this.out);
    });

    it('should set .eventWrapper', function () {
      expect(this.bindInOut.eventWrapper).toEqual({});
    });

    describe('if .in is an input', function () {
      beforeEach(function () {
        this.bindInOut = new BindInOut({ tagName: 'INPUT' });
      });

      it('should set .eventType to keyup ', function () {
        expect(this.bindInOut.eventType).toEqual('keyup');
      });
    });

    describe('if .in is a textarea', function () {
      beforeEach(function () {
        this.bindInOut = new BindInOut({ tagName: 'TEXTAREA' });
      });

      it('should set .eventType to keyup ', function () {
        expect(this.bindInOut.eventType).toEqual('keyup');
      });
    });

    describe('if .in is not an input or textarea', function () {
      beforeEach(function () {
        this.bindInOut = new BindInOut({ tagName: 'SELECT' });
      });

      it('should set .eventType to change ', function () {
        expect(this.bindInOut.eventType).toEqual('change');
      });
    });
  });

  describe('addEvents', function () {
    beforeEach(function () {
      this.in = jasmine.createSpyObj('in', ['addEventListener']);

      this.bindInOut = new BindInOut(this.in);

      this.addEvents = this.bindInOut.addEvents();
    });

    it('should set .eventWrapper.updateOut', function () {
      expect(this.bindInOut.eventWrapper.updateOut).toEqual(jasmine.any(Function));
    });

    it('should call .addEventListener', function () {
      expect(this.in.addEventListener)
        .toHaveBeenCalledWith(
          this.bindInOut.eventType,
          this.bindInOut.eventWrapper.updateOut,
        );
    });

    it('should return the instance', function () {
      expect(this.addEvents).toBe(this.bindInOut);
    });
  });

  describe('updateOut', function () {
    beforeEach(function () {
      this.in = { value: 'the-value' };
      this.out = { textContent: 'not-the-value' };

      this.bindInOut = new BindInOut(this.in, this.out);

      this.updateOut = this.bindInOut.updateOut();
    });

    it('should set .out.textContent to .in.value', function () {
      expect(this.out.textContent).toBe(this.in.value);
    });

    it('should return the instance', function () {
      expect(this.updateOut).toBe(this.bindInOut);
    });
  });

  describe('removeEvents', function () {
    beforeEach(function () {
      this.in = jasmine.createSpyObj('in', ['removeEventListener']);
      this.updateOut = () => {};

      this.bindInOut = new BindInOut(this.in);
      this.bindInOut.eventWrapper.updateOut = this.updateOut;

      this.removeEvents = this.bindInOut.removeEvents();
    });

    it('should call .removeEventListener', function () {
      expect(this.in.removeEventListener)
        .toHaveBeenCalledWith(
          this.bindInOut.eventType,
          this.updateOut,
        );
    });

    it('should return the instance', function () {
      expect(this.removeEvents).toBe(this.bindInOut);
    });
  });

  describe('initAll', function () {
    beforeEach(function () {
      this.ins = [0, 1, 2];
      this.instances = [];

      spyOn(document, 'querySelectorAll').and.returnValue(this.ins);
      spyOn(Array.prototype, 'map').and.callThrough();
      spyOn(BindInOut, 'init');

      this.initAll = BindInOut.initAll();
    });

    ClassSpecHelper.itShouldBeAStaticMethod(BindInOut, 'initAll');

    it('should call .querySelectorAll', function () {
      expect(document.querySelectorAll).toHaveBeenCalledWith('*[data-bind-in]');
    });

    it('should call .map', function () {
      expect(Array.prototype.map).toHaveBeenCalledWith(jasmine.any(Function));
    });

    it('should call .init for each element', function () {
      expect(BindInOut.init.calls.count()).toEqual(3);
    });

    it('should return an array of instances', function () {
      expect(this.initAll).toEqual(jasmine.any(Array));
    });
  });

  describe('init', function () {
    beforeEach(function () {
      spyOn(BindInOut.prototype, 'addEvents').and.callFake(function () { return this; });
      spyOn(BindInOut.prototype, 'updateOut').and.callFake(function () { return this; });

      this.init = BindInOut.init({}, {});
    });

    ClassSpecHelper.itShouldBeAStaticMethod(BindInOut, 'init');

    it('should call .addEvents', function () {
      expect(BindInOut.prototype.addEvents).toHaveBeenCalled();
    });

    it('should call .updateOut', function () {
      expect(BindInOut.prototype.updateOut).toHaveBeenCalled();
    });

    describe('if no anOut is provided', function () {
      beforeEach(function () {
        this.anIn = { dataset: { bindIn: 'the-data-bind-in' } };

        spyOn(document, 'querySelector');

        BindInOut.init(this.anIn);
      });

      it('should call .querySelector', function () {
        expect(document.querySelector)
          .toHaveBeenCalledWith(`*[data-bind-out="${this.anIn.dataset.bindIn}"]`);
      });
    });
  });
});
