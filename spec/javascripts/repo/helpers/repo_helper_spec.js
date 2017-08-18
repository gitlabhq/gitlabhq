import $ from 'jquery';
import RepoHelper from '~/repo/helpers/repo_helper';
import RepoStore from '~/repo/stores/repo_store';

describe('RepoHelper', () => {
  describe('highLightIfCurrentLine', () => {
    it('calls highlightLine if activeFile.currentLine is set', () => {
      const activeFile = {
        currentLine: '#L10',
      };
      RepoStore.activeFile = activeFile;

      spyOn(RepoHelper, 'highlightLine');

      RepoHelper.highLightIfCurrentLine();

      expect(RepoHelper.highlightLine).toHaveBeenCalledWith('10');
    });

    it('does not calls highlightLine if activeFile.currentLine is set', () => {
      const activeFile = {
        currentLine: undefined,
      };
      RepoStore.activeFile = activeFile;

      spyOn(RepoHelper, 'highlightLine');

      RepoHelper.highLightIfCurrentLine();

      expect(RepoHelper.highlightLine).not.toHaveBeenCalled();
    });
  });

  describe('diffLineNumClickWrapper', () => {
    it('queries data-line-number attr and called highlightLine', () => {
      const line = '10';
      const event = { target: {} };

      spyOn($.fn, 'attr').and.returnValue(line);
      spyOn(RepoHelper, 'highlightLine');

      RepoHelper.diffLineNumClickWrapper(event);

      expect($.fn.attr).toHaveBeenCalledWith('data-line-number');
      expect(RepoHelper.highlightLine).toHaveBeenCalledWith(line);
    });
  });

  describe('highlightLine', () => {
    it('sets background css of line', () => {
      const line = '10';
      const span = jasmine.createSpyObj('span', ['css']);
      const number = jasmine.createSpyObj('number', ['css']);

      spyOn($.fn, 'find').and.returnValues(span, number);

      RepoHelper.highlightLine(line);

      expect($.fn.find.calls.allArgs()[0][0]).toEqual('span.line');
      expect($.fn.find.calls.allArgs()[1][0]).toEqual(`.diff-line-num#LC${line}`);
      expect(span.css).toHaveBeenCalledWith('background', '#FFF');
      expect(number.css).toHaveBeenCalledWith('background', '#F8EEC7');
    });
  });

  describe('loadingError', () => {
    it('calls Flash', () => {
      spyOn(window, 'Flash');

      RepoHelper.loadingError();

      expect(window.Flash).toHaveBeenCalledWith('Unable to load the file at this time.');
    });
  });
});
