# frozen_string_literal: true

RSpec.shared_context 'with approval policy' do
  include RepoHelpers

  let(:policy_path) { Security::OrchestrationPolicyConfiguration::POLICY_PATH }
  let_it_be(:policy_project) { create(:project, :repository) }
  let(:default_branch) { policy_project.default_branch }

  let(:policy_yaml) do
    build(:orchestration_policy_yaml, scan_execution_policy: [], approval_policy: approval_policies)
  end

  let(:approval_policies) { [approval_policy] }

  before do
    policy_configuration.update_attribute(:security_policy_management_project, policy_project)

    if policy_project.repository.blob_at(default_branch, policy_path)
      policy_project.repository.delete_file(
        policy_project.creator, policy_path, message: 'delete policy', branch_name: default_branch
      )
    end

    create_file_in_repo(policy_project, default_branch, default_branch, policy_path, policy_yaml)

    stub_licensed_features(security_orchestration_policies: true)
  end
end

RSpec.shared_context 'with approval policy blocking protected branches' do
  include_context 'with approval policy' do
    let(:approval_policy) do
      build(:approval_policy, branches: [branch_name], approval_settings: { block_branch_modification: true })
    end
  end
end

RSpec.shared_context 'with approval policy blocking group-level protected branches' do
  include_context 'with approval policy' do
    let(:approval_policy) do
      build(:approval_policy, branches: [branch_name], approval_settings: { block_group_branch_modification: true })
    end
  end
end

RSpec.shared_context 'with approval policy preventing force pushing' do
  include_context 'with approval policy' do
    let(:prevent_pushing_and_force_pushing) { true }

    let(:approval_policy) do
      build(:approval_policy, branches: [branch_name],
        approval_settings: { prevent_pushing_and_force_pushing: prevent_pushing_and_force_pushing })
    end

    let(:policy_yaml) do
      build(:orchestration_policy_yaml, approval_policy: [approval_policy])
    end
  end

  after do
    policy_project.repository.delete_file(
      policy_project.creator,
      policy_path,
      message: 'Automatically deleted policy',
      branch_name: default_branch
    )
  end
end
