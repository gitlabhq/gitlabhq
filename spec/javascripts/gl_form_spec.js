/* global autosize */

window.autosize = require('vendor/autosize');
require('~/gl_form');
require('~/lib/utils/text_utility');
require('~/lib/utils/common_utils');

describe('GLForm', () => {
  const global = window.gl || (window.gl = {});
  const GLForm = global.GLForm;

  it('should be defined in the global scope', () => {
    expect(GLForm).toBeDefined();
  });

  describe('when instantiated', function () {
    beforeEach((done) => {
      this.form = $('<form class="gfm-form"><textarea class="js-gfm-input"></form>');
      this.textarea = this.form.find('textarea');
      spyOn($.prototype, 'off').and.returnValue(this.textarea);
      spyOn($.prototype, 'on').and.returnValue(this.textarea);
      spyOn($.prototype, 'css');
      spyOn(window, 'autosize');

      this.glForm = new GLForm(this.form);
      setTimeout(() => {
        $.prototype.off.calls.reset();
        $.prototype.on.calls.reset();
        $.prototype.css.calls.reset();
        autosize.calls.reset();
        done();
      });
    });

    describe('.setupAutosize', () => {
      beforeEach((done) => {
        this.glForm.setupAutosize();
        setTimeout(() => {
          done();
        });
      });

      it('should register an autosize event handler on the textarea', () => {
        expect($.prototype.off).toHaveBeenCalledWith('autosize:resized');
        expect($.prototype.on).toHaveBeenCalledWith('autosize:resized', jasmine.any(Function));
      });

      it('should register a mouseup event handler on the textarea', () => {
        expect($.prototype.off).toHaveBeenCalledWith('mouseup.autosize');
        expect($.prototype.on).toHaveBeenCalledWith('mouseup.autosize', jasmine.any(Function));
      });

      it('should autosize the textarea', () => {
        expect(autosize).toHaveBeenCalledWith(jasmine.any(Object));
      });

      it('should set the resize css property to vertical', () => {
        expect($.prototype.css).toHaveBeenCalledWith('resize', 'vertical');
      });
    });

    describe('.setHeightData', () => {
      beforeEach(() => {
        spyOn($.prototype, 'data');
        spyOn($.prototype, 'outerHeight').and.returnValue(200);
        this.glForm.setHeightData();
      });

      it('should set the height data attribute', () => {
        expect($.prototype.data).toHaveBeenCalledWith('height', 200);
      });

      it('should call outerHeight', () => {
        expect($.prototype.outerHeight).toHaveBeenCalled();
      });
    });

    describe('.destroyAutosize', () => {
      describe('when called', () => {
        beforeEach(() => {
          spyOn($.prototype, 'data');
          spyOn($.prototype, 'outerHeight').and.returnValue(200);
          spyOn(window, 'outerHeight').and.returnValue(400);
          spyOn(autosize, 'destroy');

          this.glForm.destroyAutosize();
        });

        it('should call outerHeight', () => {
          expect($.prototype.outerHeight).toHaveBeenCalled();
        });

        it('should get data-height attribute', () => {
          expect($.prototype.data).toHaveBeenCalledWith('height');
        });

        it('should call autosize destroy', () => {
          expect(autosize.destroy).toHaveBeenCalledWith(this.textarea);
        });

        it('should set the data-height attribute', () => {
          expect($.prototype.data).toHaveBeenCalledWith('height', 200);
        });

        it('should set the outerHeight', () => {
          expect($.prototype.outerHeight).toHaveBeenCalledWith(200);
        });

        it('should set the css', () => {
          expect($.prototype.css).toHaveBeenCalledWith('max-height', window.outerHeight);
        });
      });

      it('should return undefined if the data-height equals the outerHeight', () => {
        spyOn($.prototype, 'outerHeight').and.returnValue(200);
        spyOn($.prototype, 'data').and.returnValue(200);
        spyOn(autosize, 'destroy');
        expect(this.glForm.destroyAutosize()).toBeUndefined();
        expect(autosize.destroy).not.toHaveBeenCalled();
      });
    });
  });
});
