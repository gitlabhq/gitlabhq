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

    context 'when milestone is successfully reopened' do
      context 'when milestone is a project milestone' do
        let(:milestone) { create(:milestone, :closed, project: project) }

        context 'when project has active milestone hooks' do
          before do
            allow(project).to receive(:has_active_hooks?).with(:milestone_hooks).and_return(true)
          end

          it_behaves_like 'reopens the milestone', with_hooks: true, with_event: true
        end

        context 'when project has no active milestone hooks' do
          it_behaves_like 'reopens the milestone', with_hooks: false, with_event: true
        end

        context 'when milestone fails to reopen' do
          context 'when milestone is already active' do
            let(:milestone) { create(:milestone, project: project) }

            it 'does not execute hooks and does not create new event' do
              expect(service).not_to receive(:execute_hooks)
              expect { service.execute(milestone) }.not_to change { Event.count }

              expect { service.execute(milestone) }.not_to change { milestone.state }
            end
          end
        end
      end
    end
  end
end
