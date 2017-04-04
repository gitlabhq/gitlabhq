/* global ProjectNew */

require('~/project_new');

describe('Project settings', function () {
  const projectSettingsTemplate = 'projects/edit.html.raw';
  preloadFixtures(projectSettingsTemplate);

  beforeEach(() => {
    loadFixtures(projectSettingsTemplate);
    this.$requireApprovalsToggle = $('.js-require-approvals-toggle');
    this.project = new ProjectNew();
  });

  it('shows approver settings if enabled', () => {
    expect(this.$requireApprovalsToggle).not.toBeChecked();
    expect($('.nested-settings').hasClass('hidden')).toBe(true);

    this.$requireApprovalsToggle.click();
    expect($('.nested-settings').hasClass('hidden')).toBe(false);
  });

  it('hides approver settings if disabled', () => {
    expect('#require_approvals').not.toBeChecked();
    expect($('.nested-settings').hasClass('hidden')).toBe(true);

    this.$requireApprovalsToggle.click();
    this.$requireApprovalsToggle.click();
    expect($('.nested-settings').hasClass('hidden')).toBe(true);
  });

  it('sets required approvers to 0 if approvers disabled', () => {
    expect($('[name="project[approvals_before_merge]"]').val()).toBe('0');
  });

  it('sets required approvers to 1 if approvers enabled', () => {
    this.$requireApprovalsToggle.click();
    expect($('[name="project[approvals_before_merge]"]').val()).toBe('1');
  });
});
