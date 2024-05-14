# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ImportProjectTeamService, feature_category: :groups_and_projects do
  describe '#execute' do
    let_it_be(:source_project) { create(:project) }
    let_it_be(:target_project) { create(:project) }
    let_it_be(:user) { create(:user) }

    let(:source_project_id) { source_project.id }
    let(:target_project_id) { target_project.id }

    subject(:import) { described_class.new(user, { id: target_project_id, project_id: source_project_id }) }

    before_all do
      source_project.add_guest(user)
      target_project.add_maintainer(user)
    end

    context 'when project team members are imported successfully' do
      it 'returns a successful response' do
        result = import.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.success?).to be(true)
        expect(result.message).to eq('Successfully imported')
      end
    end

    context 'when the project team import fails' do
      context 'when the target project cannot be found' do
        let(:target_project_id) { non_existing_record_id }

        it 'returns unsuccessful response' do
          result = import.execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).to eq('Target project does not exist')
          expect(result.reason).to eq(:argument_error)
        end
      end

      context 'when the source project cannot be found' do
        let(:source_project_id) { non_existing_record_id }

        it 'returns unsuccessful response' do
          result = import.execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).to eq('Source project does not exist')
          expect(result.reason).to eq(:argument_error)
        end
      end

      context 'when the user doing the import does not exist' do
        let(:user) { nil }

        it 'returns unsuccessful response' do
          result = import.execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).to eq('Forbidden')
          expect(result.reason).to eq(:import_project_team_forbidden_error)
        end
      end

      context 'when the user does not have permission to read the source project members' do
        let(:source_project_id) { create(:project, :private).id }

        it 'returns unsuccessful response' do
          result = import.execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).to eq('Forbidden')
          expect(result.reason).to eq(:import_project_team_forbidden_error)
        end
      end

      context 'when the user does not have permission to admin the target project' do
        let(:target_project_id) { create(:project).id }

        it 'returns unsuccessful response' do
          result = import.execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).to eq('Forbidden')
          expect(result.reason).to eq(:import_project_team_forbidden_error)
        end
      end

      context 'when the source and target project are valid but the ProjectTeam#import command fails' do
        before do
          allow_next_instance_of(ProjectTeam) do |project_team|
            allow(project_team).to receive(:import).and_return(false)
          end
        end

        it 'returns unsuccessful response' do
          result = import.execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).to eq('Import failed')
          expect(result.reason).to eq(:import_failed_error)
        end
      end

      context 'when one of the imported project members is invalid' do
        it 'returns unsuccessful response' do
          project_bot = create(:user, :project_bot)
          source_project.add_developer(project_bot)

          result = import.execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          message = { project_bot.username => 'User project bots cannot be added to other groups / projects' }
          expect(result.message).to eq(message)
          expect(result.payload[:total_members_count]).to eq(2)
        end
      end
    end
  end
end
