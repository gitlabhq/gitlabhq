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

RSpec.shared_context 'with approval security policy preventing force pushing' do
  let(:approval_policy_preventing_force_pushing_policy_index) { 0 }

  let!(:approval_policy_preventing_force_pushing) do
    create(:security_policy, :prevent_pushing_and_force_pushing,
      security_orchestration_policy_configuration: policy_configuration,
      policy_index: approval_policy_preventing_force_pushing_policy_index)
  end

  let!(:approval_policy_rule_preventing_force_pushing) do
    create(:approval_policy_rule,
      security_policy: approval_policy_preventing_force_pushing,
      content: {
        type: 'scan_finding',
        branches: [branch_name],
        scanners: %w[container_scanning],
        vulnerabilities_allowed: 0,
        severity_levels: %w[critical],
        vulnerability_states: %w[detected]
      })
  end

  before do
    if protected_branch.project_level?
      create(:security_policy_project_link, project: protected_branch.project,
        security_policy: approval_policy_preventing_force_pushing)
    end

    stub_licensed_features(security_orchestration_policies: true)
  end
end

RSpec.shared_context 'with approval security policy blocking protected branches' do
  let(:approval_policy_blocking_protected_branches_policy_index) { 0 }

  let!(:approval_policy_blocking_protected_branches) do
    create(:security_policy, :block_branch_modification,
      security_orchestration_policy_configuration: policy_configuration,
      policy_index: approval_policy_blocking_protected_branches_policy_index)
  end

  let!(:approval_policy_rule_blocking_protected_branches) do
    create(:approval_policy_rule,
      security_policy: approval_policy_blocking_protected_branches,
      content: {
        type: 'scan_finding',
        branches: [branch_name],
        scanners: %w[container_scanning],
        vulnerabilities_allowed: 0,
        severity_levels: %w[critical],
        vulnerability_states: %w[detected]
      })
  end

  before do
    if protected_branch.project_level?
      create(:security_policy_project_link, project: protected_branch.project,
        security_policy: approval_policy_blocking_protected_branches)
    end

    stub_licensed_features(security_orchestration_policies: true)
  end
end
