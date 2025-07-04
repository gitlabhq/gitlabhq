# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestones::CreateService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:params) { { title: 'New Milestone', description: 'Description' } }

  subject(:create_milestone) { described_class.new(project, user, params) }

  describe '#execute' do
    context 'when milestone is saved successfully' do
      it 'creates a new milestone' do
        expect { create_milestone.execute }.to change { Milestone.count }.by(1)
      end

      it 'opens the milestone if it is a project milestone' do
        expect_next_instance_of(EventCreateService) do |instance|
          expect(instance).to receive(:open_milestone)
        end

        create_milestone.execute
      end

      it 'returns the created milestone' do
        milestone = create_milestone.execute
        expect(milestone).to be_a(Milestone)
        expect(milestone.title).to eq('New Milestone')
        expect(milestone.description).to eq('Description')
      end

      shared_examples 'creates the milestone' do |with_project_hooks:|
        it 'executes hooks with create action and creates new event' do
          expect(create_milestone).to receive(:execute_hooks).with(kind_of(Milestone), 'create').and_call_original
          expect(project).to receive(:execute_hooks).with(kind_of(Hash), :milestone_hooks) if with_project_hooks

          expect { create_milestone.execute }.to change { Event.count }.by(1)
        end
      end

      context 'when project has active milestone hooks' do
        let(:project) do
          create(:project).tap do |project|
            create(:project_hook, project: project, milestone_events: true)
          end
        end

        it_behaves_like 'creates the milestone', with_project_hooks: true
      end

      context 'when project has no active milestone hooks' do
        it_behaves_like 'creates the milestone', with_project_hooks: false
      end
    end

    context 'when milestone fails to save' do
      before do
        allow_next_instance_of(Milestone) do |instance|
          allow(instance).to receive(:save).and_return(false)
        end
      end

      it 'does not create a new milestone' do
        expect { create_milestone.execute }.not_to change { Milestone.count }
      end

      it 'does not open the milestone' do
        expect(EventCreateService).not_to receive(:open_milestone)

        create_milestone.execute
      end

      it 'does not execute hooks and does not create new event' do
        expect(create_milestone).not_to receive(:execute_hooks)

        expect { create_milestone.execute }.not_to change { Event.count }
      end

      it 'returns the unsaved milestone' do
        milestone = create_milestone.execute
        expect(milestone).to be_a(Milestone)
        expect(milestone.title).to eq('New Milestone')
        expect(milestone.persisted?).to be_falsey
      end
    end

    context 'when milestone is a group milestone' do
      let(:group) { create(:group) }
      let(:group_service) { described_class.new(group, user, params) }

      it 'does not execute hooks for group milestones' do
        milestone = build(:milestone, group: group)
        allow(milestone).to receive(:save).and_return(true)
        allow(group_service).to receive(:build_milestone).and_return(milestone)

        expect(group).not_to receive(:execute_hooks)

        group_service.execute
      end
    end

    it 'calls before_create method' do
      expect(create_milestone).to receive(:before_create)
      create_milestone.execute
    end
  end

  describe '#before_create' do
    it 'checks for spam' do
      milestone = build(:milestone)
      expect(milestone).to receive(:check_for_spam).with(user: user, action: :create)
      subject.send(:before_create, milestone)
    end
  end
end
