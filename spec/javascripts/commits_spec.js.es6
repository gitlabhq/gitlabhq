/* global CommitsList */

require('vendor/jquery.endless-scroll');
require('~/pager');
require('~/commits');

(() => {
  // TODO: remove this hack!
  // PhantomJS causes spyOn to panic because replaceState isn't "writable"
  let phantomjs;
  try {
    phantomjs = !Object.getOwnPropertyDescriptor(window.history, 'replaceState').writable;
  } catch (err) {
    phantomjs = false;
  }

  describe('Commits List', () => {
    beforeEach(() => {
      setFixtures(`
        <form class="commits-search-form" action="/h5bp/html5-boilerplate/commits/master">
          <input id="commits-search">
        </form>
        <ol id="commits-list"></ol>
        `);
    });

    it('should be defined', () => {
      expect(CommitsList).toBeDefined();
    });

    describe('on entering input', () => {
      let ajaxSpy;

      beforeEach(() => {
        CommitsList.init(25);
        CommitsList.searchField.val('');

        if (!phantomjs) {
          spyOn(history, 'replaceState').and.stub();
        }
        ajaxSpy = spyOn(jQuery, 'ajax').and.callFake((req) => {
          req.success({
            data: '<li>Result</li>',
          });
        });
      });

      it('should save the last search string', () => {
        CommitsList.searchField.val('GitLab');
        CommitsList.filterResults();
        expect(ajaxSpy).toHaveBeenCalled();
        expect(CommitsList.lastSearch).toEqual('GitLab');
      });

      it('should not make ajax call if the input does not change', () => {
        CommitsList.filterResults();
        expect(ajaxSpy).not.toHaveBeenCalled();
        expect(CommitsList.lastSearch).toEqual('');
      });
    });
  });
})();
