# frozen_string_literal: true

# Requires the url to the policy editor:
# - user to be logged in with the correct permissions
# - path_to_policy_editor
RSpec.shared_examples 'creating scan execution policy with valid properties' do
  include ListboxHelpers

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
    expect(page).to have_current_path(project_merge_request_path(policy_management_project, 1))
  end
end

# Requires the url to the policy editor:
# - user to be logged in with the correct permissions
# - path_to_policy_editor
RSpec.shared_examples 'creating scan execution policy with invalid properties' do
  include ListboxHelpers

  let_it_be(:limit) { 3 }

  before do
    stub_licensed_features(security_orchestration_policies: true)
    stub_application_setting(scan_execution_policies_action_limit: limit)
    visit(path_to_policy_editor)
    within_testid("scan_execution_policy-card") do
      click_link _('Select policy')
    end
  end

  let(:path_to_scan_execution_policy_editor) { "#{path_to_policy_editor}?type=scan_execution_policy" }

  it "fails to create a policy without a name" do
    click_button _('Configure with a merge request')
    expect(page).to have_current_path(path_to_scan_execution_policy_editor)
    expect(page).to have_text(_('Empty policy name'))
  end

  it "fails to create a policy without branch information for schedules" do
    fill_in _('Name'), with: 'Missing branch information'
    page.find('span', text: 'Custom').click
    within_testid('rule-0') do
      select_from_listbox 'Schedules:', from: 'Triggers:'
    end
    click_button _('Configure with a merge request')
    expect(page).to have_content('Policy cannot be enabled without branch information')
    expect(page).to have_current_path(path_to_scan_execution_policy_editor)
  end

  it "fails to create a policy without branch information" do
    fill_in _('Name'), with: 'Scan execution policy'
    page.find('span', text: 'Custom').click
    within_testid('rule-0') do
      select_from_listbox 'specific protected branches', from: 'default branch'
      fill_in _('Select branches'), with: ''
    end
    click_button _('Configure with a merge request')
    expect(page).to have_content('Policy cannot be enabled without branch information')
    expect(page).to have_current_path(path_to_scan_execution_policy_editor)
  end
end
