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
RSpec.shared_examples 'policy editor' do
  before do
    sign_in(owner)
    stub_licensed_features(security_orchestration_policies: true)
  end

  it "can create a policy when a policy project exists" do
    visit(path_to_policy_editor)
    page.within(".gl-card:nth-child(1)") do
      click_button _('Select policy')
    end
    fill_in _('Name'), with: 'Prevent vulnerabilities'
    click_button _('Select scan type')
    select_listbox_item _('Security Scan')
    page.within(find_by_testid('actions-section')) do
      click_button _('Remove')
    end
    click_button _('Configure with a merge request')
    expect(page).to have_current_path(project_merge_request_path(policy_management_project, 1))
  end
end
