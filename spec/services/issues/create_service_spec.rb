require 'spec_helper'

describe Issues::CreateService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  describe '#execute' do
    let(:issue) { described_class.new(project, user, opts).execute }

    context 'when params are valid' do
      let(:assignee) { create(:user) }
      let(:milestone) { create(:milestone, project: project) }
      let(:labels) { [create(:label, title: 'foo', project: project), create(:label, title: 'bar', project: project)] }

      before do
        project.team << [user, :master]
        project.team << [assignee, :master]
      end

      let(:opts) do
        { title: 'Awesome issue',
          description: 'please fix',
          assignee: assignee,
          label_ids: labels.map(&:id),
          milestone_id: milestone.id }
      end

      it { expect(issue).to be_valid }
      it { expect(issue.title).to eq('Awesome issue') }
      it { expect(issue.assignee).to eq assignee }
      it { expect(issue.labels).to match_array labels }
      it { expect(issue.milestone).to eq milestone }

      context 'when label belongs to different project' do
        let(:label) { create(:label) }

        let(:opts) do
          { title: 'Title',
            description: 'Description',
            label_ids: [label.id] }
        end

        it 'does not assign label'do
          expect(issue.labels).to_not include label
        end
      end

      context 'when milestone belongs to different project' do
        let(:milestone) { create(:milestone) }

        let(:opts) do
          { title: 'Title',
            description: 'Description',
            milestone_id: milestone.id }
        end

        it 'does not assign milestone' do
          expect(issue.milestone).to_not eq milestone
        end
      end
    end
  end
end
