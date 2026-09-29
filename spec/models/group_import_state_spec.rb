# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupImportState, feature_category: :importers do
  describe 'validations' do
    let_it_be(:group) { create(:group) }

    it { is_expected.to belong_to(:user).required }
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:status) }

    it 'can be created without a jid' do
      import_state = build(:group_import_state, :created, group: group, jid: nil)

      expect(import_state).to be_valid
    end

    it 'cannot be started without a jid' do
      import_state = build(:group_import_state, :started, group: group, jid: nil)

      expect(import_state).not_to be_valid
      expect(import_state.errors[:jid]).to include "can't be blank"
    end

    it 'cannot be finished without a jid' do
      import_state = build(:group_import_state, :finished, group: group, jid: nil)

      expect(import_state).not_to be_valid
      expect(import_state.errors[:jid]).to include "can't be blank"
    end

    it 'can fail without a jid' do
      import_state = build(:group_import_state, :failed, group: group, jid: nil)

      expect(import_state).to be_valid
    end
  end

  describe '#in_progress?' do
    context "when the import is 'created'" do
      it "returns true" do
        group_import_state = build(:group_import_state, :created)

        expect(group_import_state.in_progress?).to be true
      end
    end

    context "when the import is 'started'" do
      it "returns true" do
        group_import_state = build(:group_import_state, :started)

        expect(group_import_state.in_progress?).to be true
      end
    end

    context "when the import is 'finished'" do
      it "returns false" do
        group_import_state = build(:group_import_state, :finished)

        expect(group_import_state.in_progress?).to be false
      end
    end

    context "when the import is 'failed'" do
      it "returns false" do
        group_import_state = build(:group_import_state, :failed)

        expect(group_import_state.in_progress?).to be false
      end
    end
  end

  context 'when import failed' do
    context 'when error message is present' do
      it 'truncates error message' do
        group_import_state = build(:group_import_state, :started)
        group_import_state.fail_op('e' * 300)

        expect(group_import_state.last_error.length).to eq(255)
      end
    end

    context 'when error message is missing' do
      it 'has no error message' do
        group_import_state = build(:group_import_state, :started)
        group_import_state.fail_op

        expect(group_import_state.last_error).to be_nil
      end
    end
  end

  describe '#request_channel', :clean_gitlab_redis_shared_state do
    let_it_be(:group_import_state) { create(:group_import_state) }

    it 'returns nil when nothing was stored' do
      expect(group_import_state.request_channel).to be_nil
    end

    it 'round-trips a symbol as a string' do
      group_import_state.request_channel = :ui

      expect(group_import_state.request_channel).to eq('ui')
    end

    it 'is scoped per group' do
      group_import_state.request_channel = :congregate

      other_state = create(:group_import_state)

      expect(other_state.request_channel).to be_nil
    end

    it 'does not write anything when given a blank value' do
      group_import_state.request_channel = nil

      expect(group_import_state.request_channel).to be_nil
    end
  end

  describe 'import state transitions', :clean_gitlab_redis_shared_state do
    context 'when transitioning from created to started' do
      it 'tracks the start_group_import internal event' do
        group_import_state = create(:group_import_state, :created, jid: 'group_import_state_start')

        expect { group_import_state.start }
          .to trigger_internal_events('start_group_import')
          .with(
            namespace: group_import_state.group,
            user: group_import_state.user,
            additional_properties: { label: 'gitlab_group_export' }
          )
      end

      it 'includes request_channel when one was captured' do
        group_import_state = create(:group_import_state, :created, jid: 'group_import_state_start')
        group_import_state.request_channel = :congregate

        expect { group_import_state.start }
          .to trigger_internal_events('start_group_import')
          .with(
            namespace: group_import_state.group,
            user: group_import_state.user,
            additional_properties: { label: 'gitlab_group_export', request_channel: 'congregate' }
          )
      end
    end

    context 'when transitioning from started to finished' do
      it 'tracks the finish_group_import internal event without request_channel' do
        group_import_state = create(:group_import_state, :started)
        group_import_state.request_channel = :ui

        expect { group_import_state.finish }
          .to trigger_internal_events('finish_group_import')
          .with(
            namespace: group_import_state.group,
            user: group_import_state.user,
            additional_properties: { label: 'gitlab_group_export' }
          )
      end
    end

    context 'when transitioning to failed' do
      it 'tracks the fail_group_import internal event without request_channel' do
        group_import_state = create(:group_import_state, :started)
        group_import_state.request_channel = :ui

        expect { group_import_state.fail_op }
          .to trigger_internal_events('fail_group_import')
          .with(
            namespace: group_import_state.group,
            user: group_import_state.user,
            additional_properties: { label: 'gitlab_group_export' }
          )
      end
    end
  end
end
