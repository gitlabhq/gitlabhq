# frozen_string_literal: true

# Requires the url to the policy editor:
# - user to be logged in with the correct permissions
# - path_to_policy_editor
RSpec.shared_examples 'creating scan execution policy with valid properties' do
  before do
    stub_licensed_features(security_orchestration_policies: true)
    visit(path_to_policy_editor)
    within_testid("scan_execution_policy-card") do
      click_link _('Select policy')
    end
  end

  it "can create a valid policy when a policy project exists" do
    fill_in _('Name'), with: 'Run secret detection scan on every branch'
    click_button _('Configure with a merge request')
    expect(page).to have_current_path(
      project_merge_request_path(policy_management_project, 1)
    )
  end
end
