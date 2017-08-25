import SourceBranchRemovalStatus from '~/vue_merge_request_widget/components/mr_widget_source_branch_removal_status';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('MR Widget Source Branch Removal Status Component', () => {
  beforeEach(() => {
    this.component = mountComponent(SourceBranchRemovalStatus);
  });

  it('renders the message', () => {
    const $message = this.component.$el;
    expect($message).not.toBeNull();
    expect($message.querySelector('.status-text').textContent).toContain('Removes source branch');
  });

  it('renders the help icon', () => {
    const $icon = this.component.$el.querySelector('.fa-question-circle');
    expect($icon).not.toBeNull();
  });

  it('provides content for the tooltip', () => {
    const $icon = this.component.$el.querySelector('.fa-question-circle');
    expect($icon.getAttribute('data-original-title')).toBe('A user with write access to the source branch selected this option');
  });
});
