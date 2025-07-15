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
    # Approval Policy from ee/spec/fixtures/security_orchestration.yml
    expect(page).to have_content 'critical vulnerability CS approvals'
  end
end
