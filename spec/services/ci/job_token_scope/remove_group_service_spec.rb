# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobTokenScope::RemoveGroupService, feature_category: :continuous_integration do
  let(:service) { described_class.new(project, current_user) }

  let_it_be(:project) { create(:project, ci_outbound_job_token_scope_enabled: true).tap(&:save!) }
  let_it_be(:target_group) { create(:group, :private) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:link) do
    create(:ci_job_token_group_scope_link,
      source_project: project,
      target_group: target_group)
  end

  shared_examples 'removes group' do
    it 'removes the group from the scope' do
      expect do
        expect(result).to be_success
        expect(result.payload).to eq(link)
      end.to change { Ci::JobToken::GroupScopeLink.count }.by(-1)
    end
  end

  shared_examples 'returns error' do |error|
    it 'returns an error response', :aggregate_failures do
      expect(result).to be_error
      expect(result.message).to eq(error)
    end
  end

  describe '#execute' do
    subject(:result) { service.execute(target_group) }

    context 'when user has permissions on source and target group' do
      before_all do
        project.add_maintainer(current_user)
        target_group.add_developer(current_user)
      end

      it_behaves_like 'removes group'

      context 'when token scope is disabled' do
        before do
          project.ci_cd_settings.update!(job_token_scope_enabled: false)
        end

        it_behaves_like 'removes group'
      end
    end

    context 'when user has no permissions on target_group' do
      before_all do
        project.add_maintainer(current_user)
      end

      it_behaves_like 'removes group'
    end

    context 'when target group is not in the job token scope' do
      let_it_be(:target_group) { create(:group, :public) }

      before_all do
        project.add_maintainer(current_user)

        expect(target_group.id).not_to eq(link.target_group_id)
      end

      it_behaves_like 'returns error', 'Target group is not in the job token scope'
    end

    context 'when user has no permissions on source project' do
      before_all do
        target_group.add_developer(current_user)
      end

      it_behaves_like 'returns error', 'Insufficient permissions to modify the job token scope'
    end

    context 'when there is error to delete a link' do
      before_all do
        project.add_maintainer(current_user)
        target_group.add_developer(current_user)
      end

      before do
        allow(::Ci::JobToken::GroupScopeLink).to receive(:for_source_and_target).and_return(link)
        allow(link).to receive(:destroy).and_return(false)
        allow(link).to receive(:errors).and_return(ActiveModel::Errors.new(link))
        link.errors.add(:base, 'Custom error message')
      end

      it_behaves_like 'returns error', 'Custom error message'
    end
  end
end
