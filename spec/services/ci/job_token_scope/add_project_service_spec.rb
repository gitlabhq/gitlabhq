# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::JobTokenScope::AddProjectService do
  let(:service) { described_class.new(project, current_user) }

  let_it_be(:project) { create(:project) }
  let_it_be(:target_project) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  describe '#execute' do
    subject(:result) { service.execute(target_project) }

    shared_examples 'returns error' do |error|
      it 'returns an error response', :aggregate_failures do
        expect(result).to be_error
        expect(result.message).to eq(error)
      end
    end

    context 'when job token scope is disabled for the given project' do
      before do
        allow(project).to receive(:ci_job_token_scope_enabled?).and_return(false)
      end

      it_behaves_like 'returns error', 'Job token scope is disabled for this project'
    end

    context 'when user does not have permissions to edit the job token scope' do
      it_behaves_like 'returns error', 'Insufficient permissions to modify the job token scope'
    end

    context 'when user has permissions to edit the job token scope' do
      before do
        project.add_maintainer(current_user)
      end

      context 'when target project is not provided' do
        let(:target_project) { nil }

        it_behaves_like 'returns error', Ci::JobTokenScope::AddProjectService::TARGET_PROJECT_UNAUTHORIZED_OR_UNFOUND
      end

      context 'when target project is provided' do
        context 'when user does not have permissions to read the target project' do
          it_behaves_like 'returns error', Ci::JobTokenScope::AddProjectService::TARGET_PROJECT_UNAUTHORIZED_OR_UNFOUND
        end

        context 'when user has permissions to read the target project' do
          before do
            target_project.add_guest(current_user)
          end

          it 'adds the project to the scope' do
            expect do
              expect(result).to be_success
            end.to change { Ci::JobToken::ProjectScopeLink.count }.by(1)
          end

          context 'when target project is already in scope' do
            before do
              create(:ci_job_token_project_scope_link,
                source_project: project,
                target_project: target_project)
            end

            it_behaves_like 'returns error', "Target project is already in the job token scope"
          end
        end

        context 'when target project is same as the source project' do
          let(:target_project) { project }

          it_behaves_like 'returns error', "Validation failed: Target project can't be the same as the source project"
        end
      end
    end
  end
end
