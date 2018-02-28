import Autosize from 'autosize';
import GLForm from '~/gl_form';
import '~/lib/utils/text_utility';
import '~/lib/utils/common_utils';

window.autosize = Autosize;

describe('GLForm', () => {
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
        window.autosize.calls.reset();
        done();
      });
    });

    describe('setupAutosize', () => {
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
        expect(window.autosize).toHaveBeenCalledWith(jasmine.any(Object));
      });

      it('should set the resize css property to vertical', () => {
        expect($.prototype.css).toHaveBeenCalledWith('resize', 'vertical');
      });
    });

    describe('setHeightData', () => {
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

    describe('destroyAutosize', () => {
      describe('when called', () => {
        beforeEach(() => {
          spyOn($.prototype, 'data');
          spyOn($.prototype, 'outerHeight').and.returnValue(200);
          spyOn(window, 'outerHeight').and.returnValue(400);
          spyOn(window.autosize, 'destroy');

          this.glForm.destroyAutosize();
        });

        it('should call outerHeight', () => {
          expect($.prototype.outerHeight).toHaveBeenCalled();
        });

        it('should get data-height attribute', () => {
          expect($.prototype.data).toHaveBeenCalledWith('height');
        });

        it('should call autosize destroy', () => {
          expect(window.autosize.destroy).toHaveBeenCalledWith(this.textarea);
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
        spyOn(window.autosize, 'destroy');
        expect(this.glForm.destroyAutosize()).toBeUndefined();
        expect(window.autosize.destroy).not.toHaveBeenCalled();
      });
    });
  });
});
