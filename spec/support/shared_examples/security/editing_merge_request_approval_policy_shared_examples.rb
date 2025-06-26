# frozen_string_literal: true

# Requires the url to the policy editor:
# - user to be logged in with the correct permissions
# - the page to be the policy editor
RSpec.shared_examples 'editing merge request approval policy with invalid properties' do
  before do
    allow_next_found_instance_of(Security::OrchestrationPolicyConfiguration) do |policy|
      allow(policy).to receive_messages(policy_configuration_valid?: true, policy_hash: policy_yaml,
        policy_last_updated_at: Time.current)
    end

    sign_in(owner)
    stub_licensed_features(security_orchestration_policies: true)
    visit(policy_path)
  end

  it "fails to save existing policy without name field" do
    within_testid('policies-list') do
      find_by_testid('base-dropdown-toggle', match: :first).click
      click_link 'Edit'
    end

    fill_in _('Name'), with: ''

    click_button _('Update via merge request')

    expect(page).to have_content('Empty policy name')
  end
end
