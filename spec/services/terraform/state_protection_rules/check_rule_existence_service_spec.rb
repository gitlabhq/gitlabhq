# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StateProtectionRules::CheckRuleExistenceService,
  feature_category: :infrastructure_as_code do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:owner) { project.owner }
  let_it_be(:admin) { create(:admin) }

  let(:state_name) { 'production' }
  let(:current_authenticated_job) { nil }
  let(:params) { { state_name: state_name, current_authenticated_job: current_authenticated_job } }

  subject(:result) do
    described_class.new(project: project, current_user: current_user, params: params).execute
  end

  shared_examples 'protection rule exists' do
    it 'returns success with protection_rule_exists? true' do
      expect(result).to be_success
      expect(result.payload).to eq({ protection_rule_exists?: true })
    end
  end

  shared_examples 'protection rule does not exist' do
    it 'returns success with protection_rule_exists? false' do
      expect(result).to be_success
      expect(result.payload).to eq({ protection_rule_exists?: false })
    end
  end

  context 'when feature flag is disabled' do
    let(:current_user) { developer }

    before do
      stub_feature_flags(protected_terraform_states: false)
      create(:terraform_state_protection_rule,
        project: project,
        state_name: 'production',
        minimum_access_level_for_write: :owner)
    end

    it_behaves_like 'protection rule does not exist'
  end

  context 'when no protection rule exists for the state' do
    let(:current_user) { developer }

    it_behaves_like 'protection rule does not exist'
  end

  context 'with a protection rule requiring maintainer access from anywhere' do
    let_it_be(:protection_rule) do
      create(:terraform_state_protection_rule,
        project: project,
        state_name: 'production',
        minimum_access_level_for_write: :maintainer,
        allowed_from: :anywhere)
    end

    where(:current_user, :expected_protected) do
      ref(:developer)   | true
      ref(:maintainer)  | false
      ref(:owner)       | false
    end

    with_them do
      if params[:expected_protected]
        it_behaves_like 'protection rule exists'
      else
        it_behaves_like 'protection rule does not exist'
      end
    end

    context 'when current user is an admin', :enable_admin_mode do
      let(:current_user) { admin }

      it_behaves_like 'protection rule does not exist'
    end
  end

  context 'with a protection rule requiring owner access' do
    let_it_be(:protection_rule) do
      create(:terraform_state_protection_rule,
        project: project,
        state_name: 'production',
        minimum_access_level_for_write: :owner,
        allowed_from: :anywhere)
    end

    where(:current_user, :expected_protected) do
      ref(:developer)   | true
      ref(:maintainer)  | true
      ref(:owner)       | false
    end

    with_them do
      if params[:expected_protected]
        it_behaves_like 'protection rule exists'
      else
        it_behaves_like 'protection rule does not exist'
      end
    end
  end

  context 'with allowed_from: ci_only' do
    let_it_be(:protection_rule) do
      create(:terraform_state_protection_rule,
        project: project,
        state_name: 'production',
        minimum_access_level_for_write: :maintainer,
        allowed_from: :ci_only)
    end

    let(:current_user) { maintainer }

    context 'when authenticated via CI job token' do
      let(:current_authenticated_job) { create(:ci_build, :running, project: project, user: maintainer) }

      it_behaves_like 'protection rule does not exist'
    end

    context 'when authenticated via PAT (no CI job)' do
      let(:current_authenticated_job) { nil }

      it_behaves_like 'protection rule exists'
    end
  end

  context 'with allowed_from: ci_on_protected_branch_only' do
    let_it_be(:protection_rule) do
      create(:terraform_state_protection_rule,
        project: project,
        state_name: 'production',
        minimum_access_level_for_write: :maintainer,
        allowed_from: :ci_on_protected_branch_only)
    end

    let(:current_user) { maintainer }

    context 'when CI job is on a protected branch' do
      let(:pipeline) { create(:ci_pipeline, project: project, ref: 'main') }
      let(:current_authenticated_job) do
        create(:ci_build, :running, project: project, user: maintainer, pipeline: pipeline)
      end

      before do
        allow(pipeline).to receive(:protected_ref?).and_return(true)
      end

      it_behaves_like 'protection rule does not exist'
    end

    context 'when CI job is on a non-protected branch' do
      let(:pipeline) { create(:ci_pipeline, project: project, ref: 'feature-branch') }
      let(:current_authenticated_job) do
        create(:ci_build, :running, project: project, user: maintainer, pipeline: pipeline)
      end

      before do
        allow(pipeline).to receive(:protected_ref?).and_return(false)
      end

      it_behaves_like 'protection rule exists'
    end

    context 'when authenticated via PAT (no CI job)' do
      let(:current_authenticated_job) { nil }

      it_behaves_like 'protection rule exists'
    end
  end

  context 'when allowed_from has an unknown value' do
    let(:current_user) { maintainer }

    before do
      rule = create(:terraform_state_protection_rule,
        project: project,
        state_name: 'production',
        minimum_access_level_for_write: :maintainer,
        allowed_from: :anywhere)
      rule.update_column(:allowed_from, 99)
    end

    it_behaves_like 'protection rule exists'
  end

  context 'when current user is nil' do
    let(:current_user) { nil }

    before do
      create(:terraform_state_protection_rule,
        project: project,
        state_name: 'production',
        minimum_access_level_for_write: :maintainer,
        allowed_from: :anywhere)
    end

    it_behaves_like 'protection rule exists'
  end

  context 'when state name does not match any rule' do
    let(:current_user) { developer }
    let(:state_name) { 'development' }

    before do
      create(:terraform_state_protection_rule,
        project: project,
        state_name: 'production',
        minimum_access_level_for_write: :owner)
    end

    it_behaves_like 'protection rule does not exist'
  end
end
