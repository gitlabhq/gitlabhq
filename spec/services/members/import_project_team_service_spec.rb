# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ImportProjectTeamService, feature_category: :subgroups do
  describe '#execute' do
    let_it_be(:source_project) { create(:project) }
    let_it_be(:target_project) { create(:project) }
    let_it_be(:user) { create(:user) }

    subject { described_class.new(user, { id: target_project_id, project_id: source_project_id }) }

    before_all do
      source_project.add_guest(user)
      target_project.add_maintainer(user)
    end

    context 'when project team members are imported successfully' do
      let(:source_project_id) { source_project.id }
      let(:target_project_id) { target_project.id }

      it 'returns true' do
        expect(subject.execute).to be(true)
      end
    end

    context 'when the project team import fails' do
      context 'when the target project cannot be found' do
        let(:source_project_id) { source_project.id }
        let(:target_project_id) { non_existing_record_id }

        it 'returns false' do
          expect(subject.execute).to be(false)
        end
      end

      context 'when the source project cannot be found' do
        let(:source_project_id) { non_existing_record_id }
        let(:target_project_id) { target_project.id }

        it 'returns false' do
          expect(subject.execute).to be(false)
        end
      end

      context 'when the user doing the import does not exist' do
        let(:user) { nil }
        let(:source_project_id) { source_project.id }
        let(:target_project_id) { target_project.id }

        it 'returns false' do
          expect(subject.execute).to be(false)
        end
      end

      context 'when the user does not have permission to read the source project members' do
        let(:user) { create(:user) }
        let(:source_project_id) { create(:project, :private).id }
        let(:target_project_id) { target_project.id }

        it 'returns false' do
          expect(subject.execute).to be(false)
        end
      end

      context 'when the user does not have permission to admin the target project' do
        let(:source_project_id) { source_project.id }
        let(:target_project_id) { create(:project).id }

        it 'returns false' do
          expect(subject.execute).to be(false)
        end
      end

      context 'when the source and target project are valid but the ProjectTeam#import command fails' do
        let(:source_project_id) { source_project.id }
        let(:target_project_id) { target_project.id }

        before do
          allow_next_instance_of(ProjectTeam) do |project_team|
            allow(project_team).to receive(:import).and_return(false)
          end
        end

        it 'returns false' do
          expect(subject.execute).to be(false)
        end
      end
    end
  end
end
