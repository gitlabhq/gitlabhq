import * as commentIndicatorHelper from '~/image_diff/helpers/comment_indicator_helper';
import * as mockData from '../mock_data';

describe('commentIndicatorHelper', () => {
  const { coordinate } = mockData;
  let containerEl;

  beforeEach(() => {
    containerEl = document.createElement('div');
  });

  describe('addCommentIndicator', () => {
    let buttonEl;

    beforeEach(() => {
      commentIndicatorHelper.addCommentIndicator(containerEl, coordinate);
      buttonEl = containerEl.querySelector('button');
    });

    it('should append button to container', () => {
      expect(buttonEl).toBeDefined();
    });

    describe('button', () => {
      it('should set coordinate', () => {
        expect(buttonEl.style.left).toEqual(`${coordinate.x}px`);
        expect(buttonEl.style.top).toEqual(`${coordinate.y}px`);
      });

      it('should contain image-comment-dark svg', () => {
        const svgEl = buttonEl.querySelector('svg');
        expect(svgEl).toBeDefined();

        const svgLink = svgEl.querySelector('use').getAttribute('xlink:href');
        expect(svgLink.indexOf('image-comment-dark') !== -1).toEqual(true);
      });
    });
  });

  describe('removeCommentIndicator', () => {
    it('should return removed false if there is no comment-indicator', () => {
      const result = commentIndicatorHelper.removeCommentIndicator(containerEl);
      expect(result.removed).toEqual(false);
    });

    describe('has comment indicator', () => {
      let result;

      beforeEach(() => {
        containerEl.innerHTML = `
          <div class="comment-indicator" style="left:${coordinate.x}px; top: ${coordinate.y}px;">
            <img src="${gl.TEST_HOST}/image.png">
          </div>
        `;
        result = commentIndicatorHelper.removeCommentIndicator(containerEl);
      });

      it('should remove comment indicator', () => {
        expect(containerEl.querySelector('.comment-indicator')).toBeNull();
      });

      it('should return removed true', () => {
        expect(result.removed).toEqual(true);
      });

      it('should return indicator meta', () => {
        expect(result.x).toEqual(coordinate.x);
        expect(result.y).toEqual(coordinate.y);
        expect(result.image).toBeDefined();
        expect(result.image.width).toBeDefined();
        expect(result.image.height).toBeDefined();
      });
    });
  });

  describe('showCommentIndicator', () => {
    describe('commentIndicator exists', () => {
      beforeEach(() => {
        containerEl.innerHTML = `
          <button class="comment-indicator"></button>
        `;
        commentIndicatorHelper.showCommentIndicator(containerEl, coordinate);
      });

      it('should set commentIndicator coordinates', () => {
        const commentIndicatorEl = containerEl.querySelector('.comment-indicator');
        expect(commentIndicatorEl.style.left).toEqual(`${coordinate.x}px`);
        expect(commentIndicatorEl.style.top).toEqual(`${coordinate.y}px`);
      });
    });

    describe('commentIndicator does not exist', () => {
      beforeEach(() => {
        commentIndicatorHelper.showCommentIndicator(containerEl, coordinate);
      });

      it('should addCommentIndicator', () => {
        const buttonEl = containerEl.querySelector('.comment-indicator');
        expect(buttonEl).toBeDefined();
        expect(buttonEl.style.left).toEqual(`${coordinate.x}px`);
        expect(buttonEl.style.top).toEqual(`${coordinate.y}px`);
      });
    });
  });

  describe('commentIndicatorOnClick', () => {
    let event;
    let textAreaEl;

    beforeEach(() => {
      containerEl.innerHTML = `
        <div class="diff-viewer">
          <button></button>
          <div class="note-container">
            <textarea class="note-textarea"></textarea>
          </div>
        </div>
      `;
      textAreaEl = containerEl.querySelector('textarea');

      event = {
        stopPropagation: () => {},
        currentTarget: containerEl.querySelector('button'),
      };

      spyOn(event, 'stopPropagation');
      spyOn(textAreaEl, 'focus');
      commentIndicatorHelper.commentIndicatorOnClick(event);
    });

    it('should stopPropagation', () => {
      expect(event.stopPropagation).toHaveBeenCalled();
    });

    it('should focus textAreaEl', () => {
      expect(textAreaEl.focus).toHaveBeenCalled();
    });
  });
});
