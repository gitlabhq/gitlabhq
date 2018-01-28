import 'vendor/jquery.endless-scroll';
import CommitsList from '~/commits';

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

  describe('processCommits', () => {
    it('should join commit headers', () => {
      CommitsList.$contentList = $(`
        <div>
          <li class="commit-header" data-day="2016-09-20">
            <span class="day">20 Sep, 2016</span>
            <span class="commits-count">1 commit</span>
          </li>
          <li class="commit"></li>
        </div>
      `);

      const data = `
        <li class="commit-header" data-day="2016-09-20">
          <span class="day">20 Sep, 2016</span>
          <span class="commits-count">1 commit</span>
        </li>
        <li class="commit"></li>
      `;

      // The last commit header should be removed
      // since the previous one has the same data-day value.
      expect(CommitsList.processCommits(data).find('li.commit-header').length).toBe(0);
    });
  });

  describe('on entering input', () => {
    let ajaxSpy;

    beforeEach(() => {
      CommitsList.init(25);
      CommitsList.searchField.val('');

      spyOn(history, 'replaceState').and.stub();
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
