# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::JobTokenScope::AddProjectService, feature_category: :continuous_integration do
  let(:service) { described_class.new(project, current_user) }

  let_it_be(:project) { create(:project, ci_outbound_job_token_scope_enabled: true).tap(&:save!) }
  let_it_be(:target_project) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  shared_examples 'adds project' do |context|
    it 'adds the project to the scope' do
      expect do
        expect(result).to be_success
      end.to change { Ci::JobToken::ProjectScopeLink.count }.by(1)
    end
  end

  describe '#execute' do
    subject(:result) { service.execute(target_project) }

    it_behaves_like 'editable job token scope' do
      context 'when user has permissions on source and target projects' do
        let(:resulting_direction) { result.payload.fetch(:project_link)&.direction }

        before do
          project.add_maintainer(current_user)
          target_project.add_developer(current_user)
        end

        it_behaves_like 'adds project'

        context 'when token scope is disabled' do
          before do
            project.ci_cd_settings.update!(job_token_scope_enabled: false)
          end

          it_behaves_like 'adds project'

          it 'creates an inbound link by default' do
            expect(resulting_direction).to eq('inbound')
          end

          context 'when direction is specified' do
            subject(:result) { service.execute(target_project, direction: direction) }

            context 'when the direction is outbound' do
              let(:direction) { :outbound }

              specify { expect(resulting_direction).to eq('outbound') }
            end

            context 'when the direction is inbound' do
              let(:direction) { :inbound }

              specify { expect(resulting_direction).to eq('inbound') }
            end
          end
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
