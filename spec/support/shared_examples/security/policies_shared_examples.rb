# frozen_string_literal: true

# Requires the url to the policies list:
# - path_to_policies_list
RSpec.shared_examples 'policies list' do
  before do
    allow_next_found_instance_of(Security::OrchestrationPolicyConfiguration) do |policy|
      allow(policy).to receive(:policy_configuration_valid?).and_return(true)
      allow(policy).to receive(:policy_hash).and_return(policy_yaml)
      allow(policy).to receive(:policy_last_updated_at).and_return(Time.current)
    end
    sign_in(owner)
    stub_licensed_features(security_orchestration_policies: true)
  end

  it "shows the policies list with policies" do
    visit(path_to_policies_list)

    # Scan Execution Policy from ee/spec/fixtures/security_orchestration.yml
    expect(page).to have_content 'Run DAST in every pipeline'
    # Scan Result Policy from ee/spec/fixtures/security_orchestration.yml
    expect(page).to have_content 'critical vulnerability CS approvals'
  end
end

# Requires the url to the policy editor:
# - path_to_policy_editor
RSpec.shared_examples 'merge request approval policy editor' do
  before do
    sign_in(owner)
    stub_licensed_features(security_orchestration_policies: true)
  end

  it "can create a policy when a policy project exists" do
    visit(path_to_policy_editor)
    within_testid("approval_policy-card") do
      click_link _('Select policy')
    end
    fill_in _('Name'), with: 'Prevent vulnerabilities'
    click_button _('Select scan type')
    select_listbox_item _('Security Scan')
    within_testid('disabled-actions') do
      click_button _('Remove'), match: :first
    end
    click_button _('Configure with a merge request')
    expect(page).to have_current_path(project_merge_request_path(policy_management_project, 1))
  end
end

# Requires the url to the policy editor:
# - path_to_merge_request_approval_policy_editor
# - path_to_merge_request_approval_policy_editor
RSpec.shared_examples 'merge request approval policy invalid policy properties' do
  let(:merge_request_approval_policy_with_exceeding_number_of_rules) do
    fixture_file('security_orchestration/merge_request_approval_policy_with_exceeding_number_of_rules.yml', dir: 'ee')
  end

  it "fails to create a policy without name" do
    click_button _('Configure with a merge request')

    expect(page).to have_content('Empty policy name')
    expect(page).to have_current_path(path_to_merge_request_approval_policy_editor)
  end

  it "fails to create a policy without approvers" do
    fill_in _('Name'), with: 'Missing approvers'
    click_button _('Configure with a merge request')

    expect(page).to have_content('Required approvals exceed eligible approvers.')
    expect(page).to have_current_path(path_to_merge_request_approval_policy_editor)
  end

  it "fails to create a policy without rules" do
    fill_in _('Name'), with: 'Missing rules'

    page.within(find_by_testid('disabled-actions')) do
      select_from_listbox 'Roles', from: 'Choose approver type'
      select_from_listbox 'Owner', from: 'Choose specific role'
    end

    click_button _('Configure with a merge request')

    expect(page).to have_content("Invalid policy YAML")
    expect(page).to have_current_path(path_to_merge_request_approval_policy_editor)
  end

  it "fails to create policy with exceeding number of rules" do
    click_button _('.yaml mode')
    editor_set_value(merge_request_approval_policy_with_exceeding_number_of_rules.to_s)

    click_button _('Configure with a merge request')

    expect(page).to have_content("Invalid policy YAML")
    expect(page).to have_current_path(path_to_merge_request_approval_policy_editor)
  end
end
