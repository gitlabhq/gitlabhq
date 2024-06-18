# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Milestones::UpdateService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:milestone) { create(:milestone, project: project) }
  let_it_be(:params) { { title: 'New Title' } }

  subject(:update_milestone) { described_class.new(project, user, params) }

  shared_examples 'publish event store' do |attributes: []|
    specify do
      expect { update_milestone.execute(milestone) }
        .to publish_event(Milestones::MilestoneUpdatedEvent)
          .with({
            id: milestone.id,
            project_id: milestone.project_id,
            updated_attributes: attributes
          }.compact_blank)
    end
  end

  describe '#execute' do
    context 'when state_event is "activate"' do
      let(:params) { { state_event: 'activate' } }

      include_examples 'publish event store'

      it 'calls Milestones::ReopenService' do
        reopen_service = instance_double(Milestones::ReopenService)
        expect(Milestones::ReopenService).to receive(:new).with(project, user, {}).and_return(reopen_service)
        expect(reopen_service).to receive(:execute).with(milestone)

        update_milestone.execute(milestone)
      end
    end

    context 'when state_event is "close"' do
      let(:params) { { state_event: 'close' } }

      include_examples 'publish event store'

      it 'calls Milestones::CloseService' do
        close_service = instance_double(Milestones::CloseService)
        expect(Milestones::CloseService).to receive(:new).with(project, user, {}).and_return(close_service)
        expect(close_service).to receive(:execute).with(milestone)

        update_milestone.execute(milestone)
      end
    end

    context 'when params are present' do
      include_examples 'publish event store',
        attributes: %w[
          title
          updated_at
          title_html
          lock_version
        ]

      it 'assigns the params to the milestone' do
        expect(milestone).to receive(:assign_attributes).with(params.except(:state_event))

        update_milestone.execute(milestone)
      end
    end

    context 'when milestone is changed' do
      before do
        allow(milestone).to receive(:changed?).and_return(true)
      end

      it 'calls before_update' do
        expect(update_milestone).to receive(:before_update).with(milestone)

        update_milestone.execute(milestone)
      end
    end

    context 'when milestone is not changed' do
      before do
        allow(milestone).to receive(:changed?).and_return(false)
      end

      it 'does not call before_update' do
        expect(update_milestone).not_to receive(:before_update)

        update_milestone.execute(milestone)
      end
    end

    it 'saves the milestone' do
      expect(milestone).to receive(:save)

      update_milestone.execute(milestone)
    end

    it 'returns the milestone' do
      expect(update_milestone.execute(milestone)).to eq(milestone)
    end
  end

  describe '#before_update' do
    it 'checks for spam' do
      expect(milestone).to receive(:check_for_spam).with(user: user, action: :update)

      update_milestone.send(:before_update, milestone)
    end
  end
end
