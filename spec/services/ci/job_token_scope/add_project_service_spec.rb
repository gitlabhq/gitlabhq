# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::JobTokenScope::AddProjectService, feature_category: :continuous_integration do
  let(:service) { described_class.new(project, current_user) }

  let_it_be(:project) { create(:project, ci_outbound_job_token_scope_enabled: true).tap(&:save!) }
  let_it_be(:target_project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:policies) { %w[read_containers read_packages] }

  shared_examples 'adds project' do |context|
    it 'adds the project to the scope', :aggregate_failures do
      expect { result }.to change { Ci::JobToken::ProjectScopeLink.count }.by(1)

      expect(result).to be_success

      project_link = result.payload[:project_link]

      expect(project_link.source_project).to eq(project)
      expect(project_link.target_project).to eq(target_project)
      expect(project_link.added_by).to eq(current_user)
      expect(project_link.default_permissions).to eq(default_permissions)
      expect(project_link.job_token_policies).to eq(policies)
    end

    context 'when feature-flag `add_policies_to_ci_job_token` is disabled' do
      before do
        stub_feature_flags(add_policies_to_ci_job_token: false)
      end

      it 'adds the project to the scope but without the policies', :aggregate_failures do
        expect { result }.to change { Ci::JobToken::ProjectScopeLink.count }.by(1)

        expect(result).to be_success

        project_link = result.payload[:project_link]

        expect(project_link.source_project).to eq(project)
        expect(project_link.target_project).to eq(target_project)
        expect(project_link.added_by).to eq(current_user)
        expect(project_link.default_permissions).to be(true)
        expect(project_link.job_token_policies).to eq([])
      end
    end
  end

  describe '#execute' do
    subject(:result) { service.execute(target_project, default_permissions: default_permissions, policies: policies) }

    let(:default_permissions) { false }

    it_behaves_like 'editable job token scope' do
      context 'when user has permissions on source and target projects' do
        let(:resulting_direction) { result.payload.fetch(:project_link)&.direction }

        before do
          project.add_maintainer(current_user)
          target_project.add_developer(current_user)
        end

        it_behaves_like 'adds project'

        context 'when default_permissions is set to true' do
          let(:default_permissions) { true }

          it_behaves_like 'adds project'
        end

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

      context 'when project is already in the allowlist' do
        before_all do
          project.add_maintainer(current_user)
          target_project.add_developer(current_user)
        end

        before do
          service.execute(target_project)
        end

        it_behaves_like 'returns error', 'This project is already in the job token allowlist.'
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
