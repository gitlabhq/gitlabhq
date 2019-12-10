import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import GpgBadges from '~/gpg_badges';

describe('GpgBadges', () => {
  let mock;
  const dummyCommitSha = 'n0m0rec0ffee';
  const dummyBadgeHtml = 'dummy html';
  const dummyResponse = {
    signatures: [
      {
        commit_sha: dummyCommitSha,
        html: dummyBadgeHtml,
      },
    ],
  };
  const dummyUrl = `${TEST_HOST}/dummy/signatures`;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    setFixtures(`
      <form
        class="commits-search-form js-signature-container" data-signatures-path="${dummyUrl}" action="${dummyUrl}"
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

  it('does not make a request if there is no container element', done => {
    setFixtures('');
    spyOn(axios, 'get');

    GpgBadges.fetch()
      .then(() => {
        expect(axios.get).not.toHaveBeenCalled();
      })
      .then(done)
      .catch(done.fail);
  });

  it('throws an error if the endpoint is missing', done => {
    setFixtures('<div class="js-signature-container"></div>');
    spyOn(axios, 'get');

    GpgBadges.fetch()
      .then(() => done.fail('Expected error to be thrown'))
      .catch(error => {
        expect(error.message).toBe('Missing commit signatures endpoint!');
        expect(axios.get).not.toHaveBeenCalled();
      })
      .then(done)
      .catch(done.fail);
  });

  it('displays a loading spinner', done => {
    mock.onGet(dummyUrl).replyOnce(200);

    GpgBadges.fetch()
      .then(() => {
        expect(document.querySelector('.js-loading-gpg-badge:empty')).toBe(null);
        const spinners = document.querySelectorAll('.js-loading-gpg-badge i.fa.fa-spinner.fa-spin');

        expect(spinners.length).toBe(1);
        done();
      })
      .catch(done.fail);
  });

  it('replaces the loading spinner', done => {
    mock.onGet(dummyUrl).replyOnce(200, dummyResponse);

    GpgBadges.fetch()
      .then(() => {
        expect(document.querySelector('.js-loading-gpg-badge')).toBe(null);
        const parentContainer = document.querySelector('.parent-container');

        expect(parentContainer.innerHTML.trim()).toEqual(dummyBadgeHtml);
        done();
      })
      .catch(done.fail);
  });
});
