# frozen_string_literal: true

RSpec.shared_context 'with scan result policy blocking protected branches' do
  before do
    create(
      :scan_result_policy_read,
      :blocking_protected_branches,
      project: project)

    stub_licensed_features(security_orchestration_policies: true)
  end
end
