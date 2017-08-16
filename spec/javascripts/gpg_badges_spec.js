import GpgBadges from '~/gpg_badges';

describe('GpgBadges', () => {
  const dummyCommitSha = 'n0m0rec0ffee';
  const dummyBadgeHtml = 'dummy html';
  const dummyResponse = {
    signatures: [{
      commit_sha: dummyCommitSha,
      html: dummyBadgeHtml,
    }],
  };

  beforeEach(() => {
    setFixtures(`
      <div class="parent-container">
        <div class="js-loading-gpg-badge" data-commit-sha="${dummyCommitSha}"></div>
      </div>
    `);
  });

  it('displays a loading spinner', () => {
    spyOn($, 'get').and.returnValue({
      done() {
        // intentionally left blank
      },
    });

    GpgBadges.fetch();

    expect(document.querySelector('.js-loading-gpg-badge:empty')).toBe(null);
    const spinners = document.querySelectorAll('.js-loading-gpg-badge i.fa.fa-spinner.fa-spin');
    expect(spinners.length).toBe(1);
  });

  it('replaces the loading spinner', () => {
    spyOn($, 'get').and.returnValue({
      done(callback) {
        callback(dummyResponse);
      },
    });

    GpgBadges.fetch();

    expect(document.querySelector('.js-loading-gpg-badge')).toBe(null);
    const parentContainer = document.querySelector('.parent-container');
    expect(parentContainer.innerHTML.trim()).toEqual(dummyBadgeHtml);
  });
});
