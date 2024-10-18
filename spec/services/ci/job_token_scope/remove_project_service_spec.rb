# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::JobTokenScope::RemoveProjectService, feature_category: :continuous_integration do
  let(:service) { described_class.new(project, current_user) }

  let_it_be(:project) { create(:project, ci_outbound_job_token_scope_enabled: true).tap(&:save!) }
  let_it_be(:target_project) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:link) do
    create(:ci_job_token_project_scope_link,
      source_project: project,
      target_project: target_project)
  end

  shared_examples 'removes project' do |context|
    it 'removes the project from the scope' do
      expect do
        expect(result).to be_success
        expect(result.payload).to eq(link)
      end.to change { Ci::JobToken::ProjectScopeLink.count }.by(-1)
    end
  end

  describe '#execute' do
    subject(:result) { service.execute(target_project, :outbound) }

    it_behaves_like 'editable job token scope' do
      context 'when user has permissions on source and target project' do
        before do
          project.add_maintainer(current_user)
          target_project.add_developer(current_user)
        end

        it_behaves_like 'removes project'

        context 'when token scope is disabled' do
          before do
            project.ci_cd_settings.update!(job_token_scope_enabled: false)
          end

          it_behaves_like 'removes project'
        end
      end

      context 'when target project is same as the source project' do
        before do
          project.add_maintainer(current_user)
        end

        let(:target_project) { project }

        it_behaves_like 'returns error', "Source project cannot be removed from the job token scope"
      end

      context 'when target project is not in the job token scope' do
        let_it_be(:target_project) { create(:project, :public) }

        before do
          project.add_maintainer(current_user)
        end

        it_behaves_like 'returns error', 'Target project is not in the job token scope'
      end
    end
  end
end
