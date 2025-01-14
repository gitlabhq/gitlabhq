# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobTokenScope::AddGroupService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, ci_outbound_job_token_scope_enabled: true).tap(&:save!) }
  let_it_be(:target_group) { create(:group, :private) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:policies) { %w[read_containers read_packages] }

  let(:service) { described_class.new(project, current_user) }

  shared_examples 'adds group' do |_context|
    it 'adds the group to the scope', :aggregate_failures do
      expect { result }.to change { Ci::JobToken::GroupScopeLink.count }.by(1)

      expect(result).to be_success

      group_link = result.payload[:group_link]

      expect(group_link.source_project).to eq(project)
      expect(group_link.target_group).to eq(target_group)
      expect(group_link.added_by).to eq(current_user)
      expect(group_link.default_permissions).to eq(default_permissions)
      expect(group_link.job_token_policies).to eq(policies)
    end

    context 'when feature-flag `add_policies_to_ci_job_token` is disabled' do
      before do
        stub_feature_flags(add_policies_to_ci_job_token: false)
      end

      it 'adds the group to the scope without the policies', :aggregate_failures do
        expect { result }.to change { Ci::JobToken::GroupScopeLink.count }.by(1)

        expect(result).to be_success

        group_link = result.payload[:group_link]

        expect(group_link.source_project).to eq(project)
        expect(group_link.target_group).to eq(target_group)
        expect(group_link.added_by).to eq(current_user)
        expect(group_link.default_permissions).to be(true)
        expect(group_link.job_token_policies).to eq([])
      end
    end
  end

  describe '#execute' do
    subject(:result) { service.execute(target_group, default_permissions: default_permissions, policies: policies) }

    let(:default_permissions) { false }

    it_behaves_like 'editable group job token scope' do
      context 'when user has permissions on source and target groups' do
        before_all do
          project.add_maintainer(current_user)
          target_group.add_developer(current_user)
        end

        it_behaves_like 'adds group'

        context 'when default_permissions is set to true' do
          let(:default_permissions) { true }

          it_behaves_like 'adds group'
        end

        context 'when token scope is disabled' do
          before do
            project.ci_cd_settings.update!(job_token_scope_enabled: false)
          end

          it_behaves_like 'adds group'
        end
      end

      context 'when group is already in the allowlist' do
        before_all do
          project.add_maintainer(current_user)
          target_group.add_developer(current_user)
        end

        before do
          service.execute(target_group)
        end

        it_behaves_like 'returns error', 'This group is already in the job token allowlist.'
      end

      context 'when create method raises an invalid record exception' do
        before do
          allow_next_instance_of(Ci::JobToken::Allowlist) do |link|
            allow(link)
              .to receive(:add_group!)
              .and_raise(ActiveRecord::RecordInvalid)
          end
        end

        before_all do
          project.add_maintainer(current_user)
          target_group.add_developer(current_user)
        end

        it_behaves_like 'returns error', 'Record invalid'
      end

      context 'when has no permissions on a target_group' do
        before_all do
          project.add_maintainer(current_user)
        end

        it_behaves_like 'returns error', Ci::JobTokenScope::EditScopeValidations::TARGET_GROUP_UNAUTHORIZED_OR_UNFOUND
      end

      context 'when has no permissions on a project' do
        before_all do
          target_group.add_developer(current_user)
        end

        it_behaves_like 'returns error', 'Insufficient permissions to modify the job token scope'
      end
    end
  end
end
