import ImageDiff from '~/image_diff/image_diff';
import * as imageUtility from '~/lib/utils/image_utility';
import imageDiffHelper from '~/image_diff/helpers/index';
import * as mockData from './mock_data';

describe('ImageDiff', () => {
  let element;
  let imageDiff;

  beforeEach(() => {
    setFixtures(`
      <div id="element">
        <div class="diff-file">
          <div class="js-image-frame">
            <img src="${gl.TEST_HOST}/image.png">
            <div class="comment-indicator"></div>
            <div id="badge-1" class="badge">1</div>
            <div id="badge-2" class="badge">2</div>
            <div id="badge-3" class="badge">3</div>
          </div>
          <div class="note-container">
            <div class="discussion-notes">
              <div class="js-diff-notes-toggle"></div>
              <div class="notes"></div>
            </div>
            <div class="discussion-notes">
              <div class="js-diff-notes-toggle"></div>
              <div class="notes"></div>
            </div>
          </div>
        </div>
      </div>
    `);
    element = document.getElementById('element');
  });

  describe('constructor', () => {
    beforeEach(() => {
      imageDiff = new ImageDiff(element, {
        canCreateNote: true,
        renderCommentBadge: true,
      });
    });

    it('should set el', () => {
      expect(imageDiff.el).toEqual(element);
    });

    it('should set canCreateNote', () => {
      expect(imageDiff.canCreateNote).toEqual(true);
    });

    it('should set renderCommentBadge', () => {
      expect(imageDiff.renderCommentBadge).toEqual(true);
    });

    it('should set $noteContainer', () => {
      expect(imageDiff.$noteContainer[0]).toEqual(element.querySelector('.note-container'));
    });

    describe('default', () => {
      beforeEach(() => {
        imageDiff = new ImageDiff(element);
      });

      it('should set canCreateNote as false', () => {
        expect(imageDiff.canCreateNote).toEqual(false);
      });

      it('should set renderCommentBadge as false', () => {
        expect(imageDiff.renderCommentBadge).toEqual(false);
      });
    });
  });

  describe('init', () => {
    beforeEach(() => {
      spyOn(ImageDiff.prototype, 'bindEvents').and.callFake(() => {});
      imageDiff = new ImageDiff(element);
      imageDiff.init();
    });

    it('should set imageFrameEl', () => {
      expect(imageDiff.imageFrameEl).toEqual(element.querySelector('.diff-file .js-image-frame'));
    });

    it('should set imageEl', () => {
      expect(imageDiff.imageEl).toEqual(element.querySelector('.diff-file .js-image-frame img'));
    });

    it('should call bindEvents', () => {
      expect(imageDiff.bindEvents).toHaveBeenCalled();
    });
  });

  describe('bindEvents', () => {
    let imageEl;

    beforeEach(() => {
      spyOn(imageDiffHelper, 'toggleCollapsed').and.callFake(() => {});
      spyOn(imageDiffHelper, 'commentIndicatorOnClick').and.callFake(() => {});
      spyOn(imageDiffHelper, 'removeCommentIndicator').and.callFake(() => {});
      spyOn(ImageDiff.prototype, 'imageClicked').and.callFake(() => {});
      spyOn(ImageDiff.prototype, 'addBadge').and.callFake(() => {});
      spyOn(ImageDiff.prototype, 'removeBadge').and.callFake(() => {});
      spyOn(ImageDiff.prototype, 'renderBadges').and.callFake(() => {});
      imageEl = element.querySelector('.diff-file .js-image-frame img');
    });

    describe('default', () => {
      beforeEach(() => {
        spyOn(imageUtility, 'isImageLoaded').and.returnValue(false);
        imageDiff = new ImageDiff(element);
        imageDiff.imageEl = imageEl;
        imageDiff.bindEvents();
      });

      it('should register click event delegation to js-diff-notes-toggle', () => {
        element.querySelector('.js-diff-notes-toggle').click();
        expect(imageDiffHelper.toggleCollapsed).toHaveBeenCalled();
      });

      it('should register click event delegation to comment-indicator', () => {
        element.querySelector('.comment-indicator').click();
        expect(imageDiffHelper.commentIndicatorOnClick).toHaveBeenCalled();
      });
    });

    describe('image loaded', () => {
      beforeEach(() => {
        spyOn(imageUtility, 'isImageLoaded').and.returnValue(true);
        imageDiff = new ImageDiff(element);
        imageDiff.imageEl = imageEl;
      });

      it('should renderBadges', () => {});
    });

    describe('image not loaded', () => {
      beforeEach(() => {
        spyOn(imageUtility, 'isImageLoaded').and.returnValue(false);
        imageDiff = new ImageDiff(element);
        imageDiff.imageEl = imageEl;
        imageDiff.bindEvents();
      });

      it('should registers load eventListener', () => {
        const loadEvent = new Event('load');
        imageEl.dispatchEvent(loadEvent);
        expect(imageDiff.renderBadges).toHaveBeenCalled();
      });
    });

    describe('canCreateNote', () => {
      beforeEach(() => {
        spyOn(imageUtility, 'isImageLoaded').and.returnValue(false);
        imageDiff = new ImageDiff(element, {
          canCreateNote: true,
        });
        imageDiff.imageEl = imageEl;
        imageDiff.bindEvents();
      });

      it('should register click.imageDiff event', () => {
        const event = new CustomEvent('click.imageDiff');
        element.dispatchEvent(event);
        expect(imageDiff.imageClicked).toHaveBeenCalled();
      });

      it('should register blur.imageDiff event', () => {
        const event = new CustomEvent('blur.imageDiff');
        element.dispatchEvent(event);
        expect(imageDiffHelper.removeCommentIndicator).toHaveBeenCalled();
      });

      it('should register addBadge.imageDiff event', () => {
        const event = new CustomEvent('addBadge.imageDiff');
        element.dispatchEvent(event);
        expect(imageDiff.addBadge).toHaveBeenCalled();
      });

      it('should register removeBadge.imageDiff event', () => {
        const event = new CustomEvent('removeBadge.imageDiff');
        element.dispatchEvent(event);
        expect(imageDiff.removeBadge).toHaveBeenCalled();
      });
    });

    describe('canCreateNote is false', () => {
      beforeEach(() => {
        spyOn(imageUtility, 'isImageLoaded').and.returnValue(false);
        imageDiff = new ImageDiff(element);
        imageDiff.imageEl = imageEl;
        imageDiff.bindEvents();
      });

      it('should not register click.imageDiff event', () => {
        const event = new CustomEvent('click.imageDiff');
        element.dispatchEvent(event);
        expect(imageDiff.imageClicked).not.toHaveBeenCalled();
      });
    });
  });

  describe('imageClicked', () => {
    beforeEach(() => {
      spyOn(imageDiffHelper, 'getTargetSelection').and.returnValue({
        actual: {},
        browser: {},
      });
      spyOn(imageDiffHelper, 'setPositionDataAttribute').and.callFake(() => {});
      spyOn(imageDiffHelper, 'showCommentIndicator').and.callFake(() => {});
      imageDiff = new ImageDiff(element);
      imageDiff.imageClicked({
        detail: {
          currentTarget: {},
        },
      });
    });

    it('should call getTargetSelection', () => {
      expect(imageDiffHelper.getTargetSelection).toHaveBeenCalled();
    });

    it('should call setPositionDataAttribute', () => {
      expect(imageDiffHelper.setPositionDataAttribute).toHaveBeenCalled();
    });

    it('should call showCommentIndicator', () => {
      expect(imageDiffHelper.showCommentIndicator).toHaveBeenCalled();
    });
  });

  describe('renderBadges', () => {
    beforeEach(() => {
      spyOn(ImageDiff.prototype, 'renderBadge').and.callFake(() => {});
      imageDiff = new ImageDiff(element);
      imageDiff.renderBadges();
    });

    it('should call renderBadge for each discussionEl', () => {
      const discussionEls = element.querySelectorAll('.note-container .discussion-notes .notes');
      expect(imageDiff.renderBadge.calls.count()).toEqual(discussionEls.length);
    });
  });

  describe('renderBadge', () => {
    let discussionEls;

    beforeEach(() => {
      spyOn(imageDiffHelper, 'addImageBadge').and.callFake(() => {});
      spyOn(imageDiffHelper, 'addImageCommentBadge').and.callFake(() => {});
      spyOn(imageDiffHelper, 'generateBadgeFromDiscussionDOM').and.returnValue({
        browser: {},
        noteId: 'noteId',
      });
      discussionEls = element.querySelectorAll('.note-container .discussion-notes .notes');
      imageDiff = new ImageDiff(element);
      imageDiff.renderBadge(discussionEls[0], 0);
    });

    it('should populate imageBadges', () => {
      expect(imageDiff.imageBadges.length).toEqual(1);
    });

    describe('renderCommentBadge', () => {
      beforeEach(() => {
        imageDiff.renderCommentBadge = true;
        imageDiff.renderBadge(discussionEls[0], 0);
      });

      it('should call addImageCommentBadge', () => {
        expect(imageDiffHelper.addImageCommentBadge).toHaveBeenCalled();
      });
    });

    describe('renderCommentBadge is false', () => {
      it('should call addImageBadge', () => {
        expect(imageDiffHelper.addImageBadge).toHaveBeenCalled();
      });
    });
  });

  describe('addBadge', () => {
    beforeEach(() => {
      spyOn(imageDiffHelper, 'addImageBadge').and.callFake(() => {});
      spyOn(imageDiffHelper, 'addAvatarBadge').and.callFake(() => {});
      spyOn(imageDiffHelper, 'updateDiscussionBadgeNumber').and.callFake(() => {});
      imageDiff = new ImageDiff(element);
      imageDiff.imageFrameEl = element.querySelector('.diff-file .js-image-frame');
      imageDiff.addBadge({
        detail: {
          x: 0,
          y: 1,
          width: 25,
          height: 50,
          noteId: 'noteId',
          discussionId: 'discussionId',
        },
      });
    });

    it('should add imageBadge to imageBadges', () => {
      expect(imageDiff.imageBadges.length).toEqual(1);
    });

    it('should call addImageBadge', () => {
      expect(imageDiffHelper.addImageBadge).toHaveBeenCalled();
    });

    it('should call addAvatarBadge', () => {
      expect(imageDiffHelper.addAvatarBadge).toHaveBeenCalled();
    });

    it('should call updateDiscussionBadgeNumber', () => {
      expect(imageDiffHelper.updateDiscussionBadgeNumber).toHaveBeenCalled();
    });
  });

  describe('removeBadge', () => {
    beforeEach(() => {
      const { imageMeta } = mockData;

      spyOn(imageDiffHelper, 'updateDiscussionBadgeNumber').and.callFake(() => {});
      spyOn(imageDiffHelper, 'updateDiscussionAvatarBadgeNumber').and.callFake(() => {});
      imageDiff = new ImageDiff(element);
      imageDiff.imageBadges = [imageMeta, imageMeta, imageMeta];
      imageDiff.imageFrameEl = element.querySelector('.diff-file .js-image-frame');
      imageDiff.removeBadge({
        detail: {
          badgeNumber: 2,
        },
      });
    });

    describe('cascade badge count', () => {
      it('should update next imageBadgeEl value', () => {
        const imageBadgeEls = imageDiff.imageFrameEl.querySelectorAll('.badge');
        expect(imageBadgeEls[0].innerText).toEqual('1');
        expect(imageBadgeEls[1].innerText).toEqual('2');
        expect(imageBadgeEls.length).toEqual(2);
      });

      it('should call updateDiscussionBadgeNumber', () => {
        expect(imageDiffHelper.updateDiscussionBadgeNumber).toHaveBeenCalled();
      });

      it('should call updateDiscussionAvatarBadgeNumber', () => {
        expect(imageDiffHelper.updateDiscussionAvatarBadgeNumber).toHaveBeenCalled();
      });
    });

    it('should remove badge from imageBadges', () => {
      expect(imageDiff.imageBadges.length).toEqual(2);
    });

    it('should remove imageBadgeEl', () => {
      expect(imageDiff.imageFrameEl.querySelector('#badge-2')).toBeNull();
    });
  });
});
