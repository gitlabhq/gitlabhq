import $ from 'jquery';
import ProjectNew from '~/pages/projects/shared/project_new';

describe('ApproversSelect', function () {
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
    expect($('.js-current-approvers').hasClass('hidden')).toBe(false);
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

  it('sets minimum for approvers field if enabled', () => {
    expect($('[name="project[approvals_before_merge]"]').attr('min')).toBe('0');
    this.$requireApprovalsToggle.click();
    expect($('[name="project[approvals_before_merge]"]').attr('min')).toBe('1');
  });
});
