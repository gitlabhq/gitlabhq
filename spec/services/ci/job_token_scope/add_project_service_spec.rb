# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::JobTokenScope::AddProjectService do
  let(:service) { described_class.new(project, current_user) }

  let_it_be(:project) { create(:project, ci_job_token_scope_enabled: true).tap(&:save!) }
  let_it_be(:target_project) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  describe '#execute' do
    subject(:result) { service.execute(target_project) }

    it_behaves_like 'editable job token scope' do
      context 'when user has permissions on source and target projects' do
        before do
          project.add_maintainer(current_user)
          target_project.add_developer(current_user)
        end

        it 'adds the project to the scope' do
          expect do
            expect(result).to be_success
          end.to change { Ci::JobToken::ProjectScopeLink.count }.by(1)
        end
      end

      context 'when target project is same as the source project' do
        before do
          project.add_maintainer(current_user)
        end

        let(:target_project) { project }

        it_behaves_like 'returns error', "Validation failed: Target project can't be the same as the source project"
      end
    end
  end
end
