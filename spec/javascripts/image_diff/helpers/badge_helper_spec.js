import * as badgeHelper from '~/image_diff/helpers/badge_helper';
import * as mockData from '../mock_data';

describe('badge helper', () => {
  const { coordinate, noteId, badgeText, badgeNumber } = mockData;
  let containerEl;
  let buttonEl;

  beforeEach(() => {
    containerEl = document.createElement('div');
  });

  describe('createImageBadge', () => {
    beforeEach(() => {
      buttonEl = badgeHelper.createImageBadge(noteId, coordinate);
    });

    it('should create button', () => {
      expect(buttonEl.tagName).toEqual('BUTTON');
      expect(buttonEl.getAttribute('type')).toEqual('button');
    });

    it('should set disabled attribute', () => {
      expect(buttonEl.hasAttribute('disabled')).toEqual(true);
    });

    it('should set noteId', () => {
      expect(buttonEl.dataset.noteId).toEqual(noteId);
    });

    it('should set coordinate', () => {
      expect(buttonEl.style.left).toEqual(`${coordinate.x}px`);
      expect(buttonEl.style.top).toEqual(`${coordinate.y}px`);
    });

    describe('classNames', () => {
      it('should set .js-image-badge by default', () => {
        expect(buttonEl.className).toEqual('js-image-badge');
      });

      it('should add additional class names if parameter is passed', () => {
        const classNames = ['first-class', 'second-class'];
        buttonEl = badgeHelper.createImageBadge(noteId, coordinate, classNames);

        expect(buttonEl.className).toEqual(classNames.concat('js-image-badge').join(' '));
      });
    });
  });

  describe('addImageBadge', () => {
    beforeEach(() => {
      badgeHelper.addImageBadge(containerEl, {
        coordinate,
        badgeText,
        noteId,
      });
      buttonEl = containerEl.querySelector('button');
    });

    it('should appends button to container', () => {
      expect(buttonEl).toBeDefined();
    });

    it('should set the badge text', () => {
      expect(buttonEl.innerText).toEqual(badgeText);
    });

    it('should set the button coordinates', () => {
      expect(buttonEl.style.left).toEqual(`${coordinate.x}px`);
      expect(buttonEl.style.top).toEqual(`${coordinate.y}px`);
    });

    it('should set the button noteId', () => {
      expect(buttonEl.dataset.noteId).toEqual(noteId);
    });
  });

  describe('addImageCommentBadge', () => {
    beforeEach(() => {
      badgeHelper.addImageCommentBadge(containerEl, {
        coordinate,
        noteId,
      });
      buttonEl = containerEl.querySelector('button');
    });

    it('should append icon button to container', () => {
      expect(buttonEl).toBeDefined();
    });

    it('should create icon comment button', () => {
      const iconEl = buttonEl.querySelector('svg');
      expect(iconEl).toBeDefined();
    });
  });

  describe('addAvatarBadge', () => {
    let avatarBadgeEl;

    beforeEach(() => {
      containerEl.innerHTML = `
        <div id="${noteId}">
          <div class="badge hidden">
          </div>
        </div>
      `;

      badgeHelper.addAvatarBadge(containerEl, {
        detail: {
          noteId,
          badgeNumber,
        },
      });
      avatarBadgeEl = containerEl.querySelector(`#${noteId} .badge`);
    });

    it('should update badge number', () => {
      expect(avatarBadgeEl.innerText).toEqual(badgeNumber.toString());
    });

    it('should remove hidden class', () => {
      expect(avatarBadgeEl.classList.contains('hidden')).toEqual(false);
    });
  });
});
