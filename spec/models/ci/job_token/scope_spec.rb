# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::Scope, feature_category: :continuous_integration, factory_default: :keep do
  include Ci::JobTokenScopeHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create_default(:project) }
  let_it_be(:user) { create_default(:user) }
  let_it_be(:namespace) { create_default(:namespace) }

  let_it_be(:source_project) do
    create(:project,
      ci_outbound_job_token_scope_enabled: true,
      ci_inbound_job_token_scope_enabled: true
    )
  end

  let(:current_project) { source_project }

  let(:scope) { described_class.new(current_project) }

  describe '#outbound_projects' do
    subject { scope.outbound_projects }

    context 'when no projects are added to the scope' do
      it 'returns the project defining the scope' do
        expect(subject).to contain_exactly(current_project)
      end
    end

    context 'when projects are added to the scope' do
      include_context 'with accessible and inaccessible projects'

      it 'returns all projects that can be accessed from a given scope' do
        expect(subject).to contain_exactly(current_project, outbound_allowlist_project, fully_accessible_project)
      end
    end
  end

  describe '#inbound_projects' do
    subject { scope.inbound_projects }

    context 'when no projects are added to the scope' do
      it 'returns the project defining the scope' do
        expect(subject).to contain_exactly(current_project)
      end
    end

    context 'when projects are added to the scope' do
      include_context 'with accessible and inaccessible projects'

      it 'returns all projects that can be accessed from a given scope' do
        expect(subject).to contain_exactly(current_project, inbound_allowlist_project)
      end
    end
  end

  describe '#groups' do
    subject { scope.groups }

    context 'when no groups are added to the scope' do
      it 'returns an empty list' do
        expect(subject).to be_empty
      end
    end

    context 'when groups are added to the scope' do
      let_it_be(:target_group) { create(:group) }

      include_context 'with projects that are with and without groups added in allowlist'

      with_them do
        it 'returns all groups that are allowed access in the job token scope' do
          expect(subject).to contain_exactly(target_group)
        end
      end
    end
  end

  describe 'accessible?' do
    subject { scope.accessible?(accessed_project) }

    context 'with groups in allowlist' do
      let_it_be(:target_group) { create(:group) }
      let_it_be(:target_project) do
        create(:project,
          ci_inbound_job_token_scope_enabled: true,
          group: target_group
        )
      end

      let(:scope) { described_class.new(target_project) }

      include_context 'with projects that are with and without groups added in allowlist'

      where(:accessed_project, :result) do
        ref(:project_with_target_project_group_in_allowlist)            | true
        ref(:project_wo_target_project_group_in_allowlist)              | false
      end

      with_them do
        it { is_expected.to eq(result) }
      end
    end

    context 'with inbound and outbound scopes enabled' do
      let_it_be(:different_root_group) { create(:group) }
      let_it_be(:project_with_different_root_ancestor) { build_stubbed(:project, namespace: different_root_group) }

      context 'when inbound and outbound access setup' do
        include_context 'with accessible and inaccessible projects'

        where(:accessed_project, :result, :same_root_ancestor) do
          ref(:current_project)                      | true  | true
          ref(:inbound_allowlist_project)            | false | true
          ref(:unscoped_project1)                    | false | true
          ref(:unscoped_project2)                    | false | true
          ref(:outbound_allowlist_project)           | false | true
          ref(:inbound_accessible_project)           | true | true
          ref(:fully_accessible_project)             | true  | true
          ref(:unscoped_public_project)              | false | true
          ref(:project_with_different_root_ancestor) | false | false
        end

        with_them do
          it 'allows self and projects allowed from both directions' do
            is_expected.to eq(result)
          end

          it 'increments the job_token_authorization_failures_counter metric ONLY for failed authorizations' do
            if result
              expect(Gitlab::Ci::Pipeline::Metrics.job_token_authorization_failures_counter)
              .not_to receive(:increment)
            else
              expect(Gitlab::Ci::Pipeline::Metrics.job_token_authorization_failures_counter)
              .to receive(:increment).with(same_root_ancestor: same_root_ancestor)
            end

            subject
          end
        end
      end
    end

    context 'with inbound scope enabled and outbound scope disabled' do
      before do
        accessed_project.update!(ci_inbound_job_token_scope_enabled: true)
        current_project.update!(ci_outbound_job_token_scope_enabled: false)
      end

      include_context 'with accessible and inaccessible projects'

      where(:accessed_project, :result) do
        ref(:current_project)            | true
        ref(:inbound_allowlist_project)  | false
        ref(:unscoped_project1)          | false
        ref(:unscoped_project2)          | false
        ref(:outbound_allowlist_project) | false
        ref(:inbound_accessible_project) | true
        ref(:fully_accessible_project)   | true
        ref(:unscoped_public_project)    | false
      end

      with_them do
        it { is_expected.to eq(result) }
      end
    end

    context 'with inbound scope disabled and outbound scope enabled and instance-level scope is false' do
      before do
        accessed_project.update!(ci_inbound_job_token_scope_enabled: false)
        current_project.update!(ci_outbound_job_token_scope_enabled: true)
        allow(::Gitlab::CurrentSettings).to receive(:enforce_ci_inbound_job_token_scope_enabled?).and_return(false)
      end

      include_context 'with accessible and inaccessible projects'

      where(:accessed_project, :result) do
        ref(:current_project)            | true
        ref(:inbound_allowlist_project)  | true
        ref(:unscoped_project1)          | true
        ref(:unscoped_project2)          | true
        ref(:outbound_allowlist_project) | true
        ref(:inbound_accessible_project) | true
        ref(:fully_accessible_project)   | true
        ref(:unscoped_public_project)    | true
      end

      with_them do
        it { is_expected.to eq(result) }
      end
    end

    describe 'metrics' do
      include_context 'with accessible and inaccessible projects'

      context 'when the accessed project has ci_inbound_job_token_scope_enabled' do
        before do
          fully_accessible_project.update!(ci_inbound_job_token_scope_enabled: true)
        end

        it 'increments the counter metric with legacy: false' do
          expect(Gitlab::Ci::Pipeline::Metrics.job_token_inbound_access_counter)
            .to receive(:increment)
            .with(legacy: false)

          scope.accessible?(fully_accessible_project)
        end

        it 'does not log authorizations' do
          expect(Ci::JobToken::Authorization).not_to receive(:log)

          scope.accessible?(fully_accessible_project)
        end
      end

      context 'when accessed project has ci_inbound_job_token_scope_enabled and instance-level scope set to false' do
        before do
          fully_accessible_project.update!(ci_inbound_job_token_scope_enabled: false)
          allow(::Gitlab::CurrentSettings).to receive(:enforce_ci_inbound_job_token_scope_enabled?).and_return(false)
        end

        it 'increments the counter metric with legacy: false' do
          expect(Gitlab::Ci::Pipeline::Metrics.job_token_inbound_access_counter)
            .to receive(:increment)
            .with(legacy: true)

          scope.accessible?(fully_accessible_project)
        end

        it 'captures authorizations', :request_store do
          expect(Ci::JobToken::Authorization)
            .to receive(:capture)
            .with(origin_project: current_project, accessed_project: fully_accessible_project)
            .once
            .and_call_original

          scope.accessible?(fully_accessible_project)

          expect(Ci::JobToken::Authorization.captured_authorizations).to eq(
            accessed_project_id: fully_accessible_project.id,
            origin_project_id: current_project.id)
        end
      end
    end
  end

  describe '#policies_allowed?' do
    subject(:policies_allowed?) { scope.policies_allowed?(accessed_project, policies) }

    let(:scope) { described_class.new(target_project) }
    let_it_be(:target_project) { create(:project) }
    let_it_be(:allowed_policy) { ::Ci::JobToken::Policies::POLICIES.first }
    let(:accessed_project) { create_inbound_accessible_project_for_policies(target_project, [allowed_policy]) }

    before do
      allow(accessed_project).to receive(:job_token_policies_enabled?).and_return(true)
    end

    shared_examples 'capturing job token policies' do
      it 'captures job token policies' do
        expect(::Ci::JobToken::Authorization).to receive(:capture_job_token_policies).with(policies)

        policies_allowed?
      end
    end

    shared_examples 'not capturing job token policies' do
      it 'does not capture job token policies' do
        expect(::Ci::JobToken::Authorization).not_to receive(:capture_job_token_policies)

        policies_allowed?
      end
    end

    context 'when no policies are given' do
      let_it_be(:policies) { [] }

      it { is_expected.to be(false) }

      it_behaves_like 'not capturing job token policies'
    end

    context 'when the policies are defined in the scope' do
      let_it_be(:policies) { [allowed_policy] }

      it { is_expected.to be(true) }

      it_behaves_like 'capturing job token policies'

      context 'when an admin policy is defined in the scope' do
        let_it_be(:allowed_policy) { 'admin_jobs' }
        let_it_be(:policies) { [:admin_jobs, :read_jobs] }

        it 'allows both the admin policy and the read policy' do
          is_expected.to be(true)
        end
      end

      context 'when the accessed project is not inbound accessible' do
        let(:accessed_project) { create(:project) }

        it { is_expected.to be(false) }

        it_behaves_like 'capturing job token policies'
      end
    end

    context 'when the policies are not defined in the scope' do
      let_it_be(:policies) { [:not_allowed_policy] }

      it { is_expected.to be(false) }

      it_behaves_like 'capturing job token policies'

      context 'when the accessed project is the target project' do
        let(:accessed_project) { target_project }

        it { is_expected.to be(true) }

        it_behaves_like 'capturing job token policies'
      end

      context 'when accessed project has ci_inbound_job_token_scope_enabled and instance-level scope set to false' do
        before do
          accessed_project.ci_inbound_job_token_scope_enabled = false
          allow(::Gitlab::CurrentSettings).to receive(:enforce_ci_inbound_job_token_scope_enabled?).and_return(false)
        end

        it { is_expected.to be(true) }

        it_behaves_like 'capturing job token policies'
      end

      context 'when job token policies are disabled' do
        before do
          allow(accessed_project).to receive(:job_token_policies_enabled?).and_return(false)
        end

        it { is_expected.to be(true) }

        it_behaves_like 'capturing job token policies'
      end

      context 'when the accessed project has not enabled fine grained permissions' do
        let(:accessed_project) { create_inbound_accessible_project(target_project) }

        it { is_expected.to be(true) }

        it_behaves_like 'capturing job token policies'
      end
    end
  end

  describe '#self_referential?' do
    subject { scope.self_referential?(access_project) }

    context 'when a current project requested' do
      let(:access_project) { current_project }

      it { is_expected.to be_truthy }
    end

    context 'when a different project requested' do
      let_it_be(:access_project) { create(:project) }

      it { is_expected.to be_falsey }
    end
  end
end
