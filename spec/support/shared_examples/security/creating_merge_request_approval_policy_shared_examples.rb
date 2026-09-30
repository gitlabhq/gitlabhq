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

# Requires the url to the policy editor:
# - path_to_policy_editor
RSpec.shared_examples 'creating merge request approval policy with invalid properties' do
  include Features::SourceEditorSpecHelpers

  let(:path_to_merge_request_approval_policy_editor) { "#{path_to_policy_editor}?type=approval_policy" }
  let(:merge_request_approval_policy_with_exceeding_number_of_rules) do
    fixture_file('security_orchestration/merge_request_approval_policy_with_exceeding_number_of_rules.yml', dir: 'ee')
  end

  before do
    stub_licensed_features(security_orchestration_policies: true)
    visit(path_to_policy_editor)
    within_testid("approval_policy-card") do
      click_link _('Select policy')
    end
  end

  # Cannot move: it drives the Monaco-backed YAML editor, which the MSW harness never
  # resolves. Its rule-mode counterpart is covered by editor/limits_spec.js.
  it "fails to create policy with exceeding number of rules" do
    click_button _('.yaml mode')
    editor_set_value(merge_request_approval_policy_with_exceeding_number_of_rules.to_s)

    click_button _('Configure with a merge request')

    expect(page).to have_content("Invalid policy")
    expect(page).to have_current_path(path_to_merge_request_approval_policy_editor)
  end
end
