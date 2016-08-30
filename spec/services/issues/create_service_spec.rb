require 'spec_helper'

describe Issues::CreateService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  describe '#execute' do
    let(:issue) { described_class.new(project, user, opts).execute }

    context 'when params are valid' do
      let(:assignee) { create(:user) }
      let(:milestone) { create(:milestone, project: project) }
      let(:labels) { create_pair(:label, project: project) }

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

      it 'creates a pending todo for new assignee' do
        attributes = {
          project: project,
          author: user,
          user: assignee,
          target_id: issue.id,
          target_type: issue.class.name,
          action: Todo::ASSIGNED,
          state: :pending
        }

        expect(Todo.where(attributes).count).to eq 1
      end

      context 'when label belongs to different project' do
        let(:label) { create(:label) }

        let(:opts) do
          { title: 'Title',
            description: 'Description',
            label_ids: [label.id] }
        end

        it 'does not assign label' do
          expect(issue.labels).not_to include label
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
          expect(issue.milestone).not_to eq milestone
        end
      end

      it 'executes issue hooks when issue is not confidential' do
        opts = { title: 'Title', description: 'Description', confidential: false }

        expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :issue_hooks)
        expect(project).to receive(:execute_services).with(an_instance_of(Hash), :issue_hooks)

        described_class.new(project, user, opts).execute
      end

      it 'executes confidential issue hooks when issue is confidential' do
        opts = { title: 'Title', description: 'Description', confidential: true }

        expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :confidential_issue_hooks)
        expect(project).to receive(:execute_services).with(an_instance_of(Hash), :confidential_issue_hooks)

        described_class.new(project, user, opts).execute
      end
    end

    it_behaves_like 'new issuable record that supports slash commands'
  end
end
