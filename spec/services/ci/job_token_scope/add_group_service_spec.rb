# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobTokenScope::AddGroupService, feature_category: :continuous_integration do
  let(:service) { described_class.new(project, current_user) }

  let_it_be(:project) { create(:project, ci_outbound_job_token_scope_enabled: true).tap(&:save!) }
  let_it_be(:target_group) { create(:group, :private) }
  let_it_be(:current_user) { create(:user) }

  shared_examples 'adds group' do |_context|
    it 'adds the group to the scope' do
      expect do
        expect(result).to be_success
      end.to change { Ci::JobToken::GroupScopeLink.count }.by(1)
    end
  end

  describe '#execute' do
    subject(:result) { service.execute(target_group) }

    it_behaves_like 'editable group job token scope' do
      context 'when user has permissions on source and target groups' do
        before_all do
          project.add_maintainer(current_user)
          target_group.add_developer(current_user)
        end

        it_behaves_like 'adds group'

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

        it_behaves_like 'returns error', 'Target group is already in the job token scope'
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
