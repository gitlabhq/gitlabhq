import $ from 'jquery';
import VersionCheckImage from '~/version_check_image';
import ClassSpecHelper from './helpers/class_spec_helper';

describe('VersionCheckImage', function () {
  describe('bindErrorEvent', function () {
    ClassSpecHelper.itShouldBeAStaticMethod(VersionCheckImage, 'bindErrorEvent');

    beforeEach(function () {
      this.imageElement = $('<div></div>');
    });

    it('registers an error event', function () {
      spyOn($.prototype, 'on');
      spyOn($.prototype, 'off').and.callFake(function () { return this; });

      VersionCheckImage.bindErrorEvent(this.imageElement);

      expect($.prototype.off).toHaveBeenCalledWith('error');
      expect($.prototype.on).toHaveBeenCalledWith('error', jasmine.any(Function));
    });

    it('hides the imageElement on error', function () {
      spyOn($.prototype, 'hide');

      VersionCheckImage.bindErrorEvent(this.imageElement);

      this.imageElement.trigger('error');

      expect($.prototype.hide).toHaveBeenCalled();
    });
  });
});
