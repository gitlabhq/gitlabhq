import ImageBadge from '~/image_diff/image_badge';
import imageDiffHelper from '~/image_diff/helpers/index';
import * as mockData from './mock_data';

describe('ImageBadge', () => {
  const { noteId, discussionId, imageMeta } = mockData;
  const options = {
    noteId,
    discussionId,
  };

  it('should save actual property', () => {
    const imageBadge = new ImageBadge(Object.assign({}, options, {
      actual: imageMeta,
    }));

    const { actual } = imageBadge;
    expect(actual.x).toEqual(imageMeta.x);
    expect(actual.y).toEqual(imageMeta.y);
    expect(actual.width).toEqual(imageMeta.width);
    expect(actual.height).toEqual(imageMeta.height);
  });

  it('should save browser property', () => {
    const imageBadge = new ImageBadge(Object.assign({}, options, {
      browser: imageMeta,
    }));

    const { browser } = imageBadge;
    expect(browser.x).toEqual(imageMeta.x);
    expect(browser.y).toEqual(imageMeta.y);
    expect(browser.width).toEqual(imageMeta.width);
    expect(browser.height).toEqual(imageMeta.height);
  });

  it('should save noteId', () => {
    const imageBadge = new ImageBadge(options);
    expect(imageBadge.noteId).toEqual(noteId);
  });

  it('should save discussionId', () => {
    const imageBadge = new ImageBadge(options);
    expect(imageBadge.discussionId).toEqual(discussionId);
  });

  describe('default values', () => {
    let imageBadge;

    beforeEach(() => {
      imageBadge = new ImageBadge(options);
    });

    it('should return defaultimageMeta if actual property is not provided', () => {
      const { actual } = imageBadge;
      expect(actual.x).toEqual(0);
      expect(actual.y).toEqual(0);
      expect(actual.width).toEqual(0);
      expect(actual.height).toEqual(0);
    });

    it('should return defaultimageMeta if browser property is not provided', () => {
      const { browser } = imageBadge;
      expect(browser.x).toEqual(0);
      expect(browser.y).toEqual(0);
      expect(browser.width).toEqual(0);
      expect(browser.height).toEqual(0);
    });
  });

  describe('imageEl property is provided and not browser property', () => {
    beforeEach(() => {
      spyOn(imageDiffHelper, 'resizeCoordinatesToImageElement').and.returnValue(true);
    });

    it('should generate browser property', () => {
      const imageBadge = new ImageBadge(Object.assign({}, options, {
        imageEl: document.createElement('img'),
      }));

      expect(imageDiffHelper.resizeCoordinatesToImageElement).toHaveBeenCalled();
      expect(imageBadge.browser).toEqual(true);
    });
  });
});
