# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobTokenScope::RemoveProjectService, feature_category: :continuous_integration do
  let(:service) { described_class.new(project, current_user) }

  let_it_be_with_reload(:project) { create(:project, ci_outbound_job_token_scope_enabled: true).tap(&:save!) }
  let_it_be(:target_project) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:link) do
    create(:ci_job_token_project_scope_link,
      source_project: project,
      target_project: target_project)
  end

  shared_examples 'returns error' do |error|
    it 'returns an error response', :aggregate_failures do
      expect(result).to be_error
      expect(result.message).to eq(error)
    end
  end

  describe '#execute' do
    subject(:result) { service.execute(target_project, :outbound) }

    context 'when user does not have permissions to edit the job token scope' do
      it_behaves_like 'returns error', 'Insufficient permissions to modify the job token scope'
    end

    context 'when user has permissions to edit the job token scope' do
      before_all do
        project.add_maintainer(current_user)
      end

      context 'when user has permissions on source and target project' do
        before_all do
          target_project.add_developer(current_user)
        end

        it 'removes the project from the scope', :aggregate_failures do
          expect { expect(result).to be_success }.to change { Ci::JobToken::ProjectScopeLink.count }.by(-1)
          expect(result.payload).to eq(link)
        end

        context 'when token scope is disabled' do
          before do
            project.ci_cd_settings.update!(job_token_scope_enabled: false)
          end

          it 'removes the project from the scope', :aggregate_failures do
            expect { expect(result).to be_success }.to change { Ci::JobToken::ProjectScopeLink.count }.by(-1)
            expect(result.payload).to eq(link)
          end
        end
      end

      context 'when user cannot read the target project' do
        let_it_be(:target_project) { create(:project, :private) }
        let_it_be(:link) do
          create(:ci_job_token_project_scope_link,
            source_project: project,
            target_project: target_project)
        end

        it 'removes the project from the scope', :aggregate_failures do
          expect { expect(result).to be_success }.to change { Ci::JobToken::ProjectScopeLink.count }.by(-1)
          expect(result.payload).to eq(link)
        end
      end

      context 'when target project is same as the source project' do
        let(:target_project) { project }

        it_behaves_like 'returns error', Ci::JobTokenScope::RemoveProjectService::SOURCE_CANNOT_BE_REMOVED
      end

      context 'when target project is not in the job token scope' do
        let_it_be(:target_project) { create(:project, :public) }

        it_behaves_like 'returns error', Ci::JobTokenScope::RemoveProjectService::TARGET_NOT_IN_SCOPE
      end
    end
  end
end
