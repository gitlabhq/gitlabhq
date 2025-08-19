# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestones::CreateService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:container) { create(:project) }
  let_it_be(:params) { { title: 'New Milestone', description: 'Description' } }

  subject(:service) { described_class.new(container, user, params) }

  describe '#execute' do
    context 'when milestone is saved successfully' do
      it 'creates a new milestone' do
        expect { service.execute }.to change { Milestone.count }.by(1)
      end

      it 'opens the milestone if it is a project milestone' do
        expect_next_instance_of(EventCreateService) do |instance|
          expect(instance).to receive(:open_milestone)
        end

        service.execute
      end

      it 'returns the created milestone' do
        milestone = service.execute
        expect(milestone).to be_a(Milestone)
        expect(milestone.title).to eq('New Milestone')
        expect(milestone.description).to eq('Description')
      end

      context 'when project has active milestone hooks' do
        before do
          allow(container).to receive(:has_active_hooks?).with(:milestone_hooks).and_return(true)
        end

        it_behaves_like 'creates the milestone', with_hooks: true, with_event: true
      end

      context 'when project has no active milestone hooks' do
        it_behaves_like 'creates the milestone', with_hooks: false, with_event: true
      end
    end

    context 'when milestone fails to save' do
      before do
        allow_next_instance_of(Milestone) do |instance|
          allow(instance).to receive(:save).and_return(false)
        end
      end

      it 'does not create a new milestone' do
        expect { service.execute }.not_to change { Milestone.count }
      end

      it 'does not open the milestone' do
        expect(EventCreateService).not_to receive(:open_milestone)

        service.execute
      end

      it 'does not execute hooks and does not create new event' do
        expect(service).not_to receive(:execute_hooks)

        expect { service.execute }.not_to change { Event.count }
      end

      it 'returns the unsaved milestone' do
        milestone = service.execute
        expect(milestone).to be_a(Milestone)
        expect(milestone.title).to eq('New Milestone')
        expect(milestone.persisted?).to be_falsey
      end
    end

    it 'calls before_create method' do
      expect(service).to receive(:before_create)
      service.execute
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
