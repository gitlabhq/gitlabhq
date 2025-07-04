# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestones::ReopenService, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:milestone) { create(:milestone, :closed, title: "Milestone v1.2", project: project) }

  before_all do
    project.add_maintainer(user)
  end

  describe '#execute' do
    let(:service) { described_class.new(project, user, {}) }

    context 'when service is called before test suite' do
      before do
        service.execute(milestone)
      end

      it { expect(milestone).to be_valid }
      it { expect(milestone).to be_active }

      describe 'event' do
        let(:event) { Event.recent.first }

        it { expect(event.milestone).to be_truthy }
        it { expect(event.target).to eq(milestone) }
        it { expect(event.action_name).to eq('opened') }
      end
    end

    shared_examples 'reopens the milestone' do |with_project_hooks:|
      it 'executes hooks with reopen action and creates new event' do
        expect(service).to receive(:execute_hooks).with(milestone, 'reopen').and_call_original
        expect(project).to receive(:execute_hooks).with(kind_of(Hash), :milestone_hooks) if with_project_hooks

        expect { service.execute(milestone) }.to change { Event.count }.by(1)
      end
    end

    shared_examples 'does not reopen the milestone' do
      it 'does not execute hooks and does not create new event' do
        expect(service).not_to receive(:execute_hooks)

        expect { service.execute(milestone) }.not_to change { Event.count }
      end
    end

    context 'when milestone is successfully reopened' do
      let(:milestone) { create(:milestone, :closed, project: project) }

      context 'when project has active milestone hooks' do
        let(:project) do
          create(:project).tap do |project|
            create(:project_hook, project: project, milestone_events: true)
          end
        end

        it_behaves_like 'reopens the milestone', with_project_hooks: true
      end

      context 'when project has no active milestone hooks' do
        it_behaves_like 'reopens the milestone', with_project_hooks: false
      end
    end

    context 'when milestone fails to reopen' do
      context 'when milestone is already active' do
        let(:milestone) { create(:milestone, project: project) }

        it_behaves_like 'does not reopen the milestone'
      end

      context 'when milestone is a group milestone' do
        let(:group) { create(:group) }
        let(:milestone) { create(:milestone, :closed, group: group) }

        it_behaves_like 'does not reopen the milestone'
      end
    end
  end
end
