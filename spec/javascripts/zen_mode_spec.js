import $ from 'jquery';
import Dropzone from 'dropzone';
import Mousetrap from 'mousetrap';
import ZenMode from '~/zen_mode';

describe('ZenMode', () => {
  let zen;
  let dropzoneForElementSpy;
  const fixtureName = 'snippets/show.html.raw';

  preloadFixtures(fixtureName);

  function enterZen() {
    $('.notes-form .js-zen-enter').click();
  }

  function exitZen() {
    $('.notes-form .js-zen-leave').click();
  }

  function escapeKeydown() {
    $('.notes-form textarea').trigger(
      $.Event('keydown', {
        keyCode: 27,
      }),
    );
  }

  beforeEach(() => {
    loadFixtures(fixtureName);

    dropzoneForElementSpy = spyOn(Dropzone, 'forElement').and.callFake(() => ({
      enable: () => true,
    }));
    zen = new ZenMode();

    // Set this manually because we can't actually scroll the window
    zen.scroll_position = 456;
  });

  describe('enabling dropzone', () => {
    beforeEach(() => {
      enterZen();
    });

    it('should not call dropzone if element is not dropzone valid', () => {
      $('.div-dropzone').addClass('js-invalid-dropzone');
      exitZen();
      expect(dropzoneForElementSpy.calls.count()).toEqual(0);
    });

    it('should call dropzone if element is dropzone valid', () => {
      $('.div-dropzone').removeClass('js-invalid-dropzone');
      exitZen();
      expect(dropzoneForElementSpy.calls.count()).toEqual(2);
    });
  });

  describe('on enter', () => {
    it('pauses Mousetrap', () => {
      const mouseTrapPauseSpy = spyOn(Mousetrap, 'pause');
      enterZen();
      expect(mouseTrapPauseSpy).toHaveBeenCalled();
    });

    it('removes textarea styling', () => {
      $('.notes-form textarea').attr('style', 'height: 400px');
      enterZen();
      expect($('.notes-form textarea')).not.toHaveAttr('style');
    });
  });

  describe('in use', () => {
    beforeEach(enterZen);

    it('exits on Escape', () => {
      escapeKeydown();
      expect($('.notes-form .zen-backdrop')).not.toHaveClass('fullscreen');
    });
  });

  describe('on exit', () => {
    beforeEach(enterZen);

    it('unpauses Mousetrap', () => {
      const mouseTrapUnpauseSpy = spyOn(Mousetrap, 'unpause');
      exitZen();
      expect(mouseTrapUnpauseSpy).toHaveBeenCalled();
    });

    it('restores the scroll position', () => {
      spyOn(zen, 'scrollTo');
      exitZen();
      expect(zen.scrollTo).toHaveBeenCalled();
    });
  });
});
