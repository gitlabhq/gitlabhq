/* global MergedButtons */

import '~/merged_buttons';

describe('MergedButtons', () => {
  const fixturesPath = 'merge_requests/merged_merge_request.html.raw';
  preloadFixtures(fixturesPath);

  beforeEach(() => {
    loadFixtures(fixturesPath);
    this.mergedButtons = new MergedButtons();
    this.$removeBranchWidget = $('.remove_source_branch_widget:not(.failed)');
    this.$removeBranchProgress = $('.remove_source_branch_in_progress');
    this.$removeBranchFailed = $('.remove_source_branch_widget.failed');
    this.$removeBranchButton = $('.remove_source_branch');
  });

  describe('removeSourceBranch', () => {
    it('shows loader', () => {
      $('.remove_source_branch').trigger('click');
      expect(this.$removeBranchProgress).toBeVisible();
      expect(this.$removeBranchWidget).not.toBeVisible();
    });
  });

  describe('removeBranchSuccess', () => {
    it('refreshes page when branch removed', () => {
      spyOn(gl.utils, 'refreshCurrentPage').and.stub();
      const response = { status: 200 };
      this.$removeBranchButton.trigger('ajax:success', response, 'xhr');
      expect(gl.utils.refreshCurrentPage).toHaveBeenCalled();
    });
  });

  describe('removeBranchError', () => {
    it('shows error message', () => {
      const response = { status: 500 };
      this.$removeBranchButton.trigger('ajax:error', response, 'xhr');
      expect(this.$removeBranchFailed).toBeVisible();
      expect(this.$removeBranchProgress).not.toBeVisible();
      expect(this.$removeBranchWidget).not.toBeVisible();
    });
  });
});
