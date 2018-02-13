import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import GpgBadges from '~/gpg_badges';

describe('GpgBadges', () => {
  let mock;
  const dummyCommitSha = 'n0m0rec0ffee';
  const dummyBadgeHtml = 'dummy html';
  const dummyResponse = {
    signatures: [{
      commit_sha: dummyCommitSha,
      html: dummyBadgeHtml,
    }],
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    setFixtures(`
      <form 
        class="commits-search-form" data-signatures-path="/hello" action="/hello"
        method="get">
        <input name="utf8" type="hidden" value="✓">
        <input type="search" name="search" id="commits-search"class="form-control search-text-input input-short">
      </form>
      <div class="parent-container">
        <div class="js-loading-gpg-badge" data-commit-sha="${dummyCommitSha}"></div>
      </div>
    `);
  });

  afterEach(() => {
    mock.restore();
  });

  it('displays a loading spinner', (done) => {
    mock.onGet('/hello').reply(200);

    GpgBadges.fetch().then(() => {
      expect(document.querySelector('.js-loading-gpg-badge:empty')).toBe(null);
      const spinners = document.querySelectorAll('.js-loading-gpg-badge i.fa.fa-spinner.fa-spin');
      expect(spinners.length).toBe(1);
      done();
    }).catch(done.fail);
  });

  it('replaces the loading spinner', (done) => {
    mock.onGet('/hello').reply(200, dummyResponse);

    GpgBadges.fetch().then(() => {
      expect(document.querySelector('.js-loading-gpg-badge')).toBe(null);
      const parentContainer = document.querySelector('.parent-container');
      expect(parentContainer.innerHTML.trim()).toEqual(dummyBadgeHtml);
      done();
    }).catch(done.fail);
  });
});
