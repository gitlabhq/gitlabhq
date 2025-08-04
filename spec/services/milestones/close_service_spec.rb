# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestones::CloseService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:project) { create(:project, maintainers: user) }

    let(:milestone) { create(:milestone, title: 'Milestone v1.2', project: project) }

    subject(:service) { described_class.new(project, user, {}) }

    context 'when service is called before test suite' do
      before do
        service.execute(milestone)
      end

      it { expect(milestone).to be_valid }
      it { expect(milestone).to be_closed }

      describe 'event' do
        let(:event) { Event.recent.first }

        it { expect(event.milestone).to be_truthy }
        it { expect(event.target).to eq(milestone) }
        it { expect(event.action_name).to eq('closed') }
      end
    end

    context 'when milestone is successfully closed' do
      context 'when project has active milestone hooks' do
        before do
          allow(project).to receive(:has_active_hooks?).with(:milestone_hooks).and_return(true)
        end

        it_behaves_like 'closes the milestone', with_hooks: true, with_event: true
      end

      context 'when project has no active milestone hooks' do
        it_behaves_like 'closes the milestone', with_hooks: false, with_event: true
      end
    end

    context 'when milestone fails to close' do
      context 'when milestone is already closed' do
        let(:milestone) { create(:milestone, :closed, project: project) }

        it 'does not execute hooks and does not create new event' do
          expect(service).not_to receive(:execute_hooks)
          expect(Event).not_to receive(:new)

          expect { service.execute(milestone) }.not_to change { milestone.state }
        end
      end
    end
  end
end
