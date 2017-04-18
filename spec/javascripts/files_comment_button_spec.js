import FilesCommentButton from '~/files_comment_button';
import _ from 'underscore';

describe('FilesCommentButton', () => {
  let filesCommentButton;

  describe('class constructor', () => {
    let filesContainerElement;
    let renderDebounce;

    beforeEach(() => {
      filesContainerElement = jasmine.createSpyObj('filesContainerElement', ['on']);
      window.notes = jasmine.createSpyObj('notes', ['isParallelView']);
      renderDebounce = () => {};

      spyOn(_, 'debounce').and.returnValue(renderDebounce);
      filesContainerElement.on.and.returnValue(filesContainerElement);

      filesCommentButton = new FilesCommentButton(filesContainerElement);

      return filesCommentButton;
    });

    it('should call _.debounce', () => {
      expect(_.debounce).toHaveBeenCalledWith(jasmine.any(Function), 100);
    });

    it('should call .on', () => {
      const allArgs = filesContainerElement.on.calls.allArgs();
      const targetSelector = '.diff-line-num, .line_content';

      expect(allArgs[0]).toEqual(['mouseover', targetSelector, renderDebounce]);
      expect(allArgs[1]).toEqual(['mouseleave', targetSelector, jasmine.any(Function)]);
    });

    describe('mouseleave function', () => {
      let mouseleaveFunction;

      function onFake(eventName, targetSelector, handler) {
        if (eventName === 'mouseleave') mouseleaveFunction = handler;

        return filesContainerElement;
      }

      beforeEach(() => {
        spyOn(window, 'setTimeout');
        filesContainerElement.on.and.callFake(onFake);

        filesCommentButton = new FilesCommentButton(filesContainerElement);

        mouseleaveFunction();
      });

      it('should call setTimeout', () => {
        expect(window.setTimeout).toHaveBeenCalledWith(jasmine.any(Function), 100);
      });
    });
  });
});
