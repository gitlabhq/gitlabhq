# frozen_string_literal: true

# Requires the url to the policy editor:
# - path_to_policy_editor
RSpec.shared_examples 'creating merge request approval policy with valid properties' do
  include ListboxHelpers

  before do
    stub_licensed_features(security_orchestration_policies: true)
    visit(path_to_policy_editor)
    within_testid("approval_policy-card") do
      click_link _('Select policy')
    end
  end

  it "can create a policy when a policy project exists" do
    fill_in _('Name'), with: 'Prevent vulnerabilities'
    click_button s_('SecurityOrchestration|select scan type')
    select_listbox_item s_('SecurityOrchestration|security scan')
    within_testid('disabled-actions') do
      click_button _('Remove'), match: :first
    end
    click_button _('Configure with a merge request')
    expect(page).to have_current_path(project_merge_request_path(policy_management_project, 1))
  end
end
