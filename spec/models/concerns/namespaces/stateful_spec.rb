# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:namespace) { create(:namespace) }

  describe 'STATES constant' do
    it 'defines all expected states' do
      expect(described_class::STATES).to eq({
        'ancestor_inherited' => nil,
        'archived' => 1,
        'deletion_scheduled' => 2,
        'creation_in_progress' => 3,
        'deletion_in_progress' => 4,
        'transfer_in_progress' => 5,
        'maintenance' => 6
      })
    end

    it 'is frozen' do
      expect(described_class::STATES).to be_frozen
    end
  end

  describe 'state machine' do
    subject { namespace }

    it "declares all expected states" do
      is_expected.to have_states :ancestor_inherited, :archived, :deletion_scheduled,
        :creation_in_progress, :deletion_in_progress,
        :transfer_in_progress, :maintenance
    end

    it 'has ancestor_inherited as initial state' do
      expect(namespace.state_name).to eq(:ancestor_inherited)
    end

    it { is_expected.to handle_events :start_transfer, when: :ancestor_inherited }
    it { is_expected.to handle_events :complete_transfer, when: :transfer_in_progress }

    it 'transitions from ancestor_inherited to transfer_in_progress on start_transfer' do
      namespace.state = described_class::STATES[:ancestor_inherited]
      expect { namespace.start_transfer(current_user: user) }
        .to change { namespace.state_name }
        .from(:ancestor_inherited)
        .to(:transfer_in_progress)
    end

    it 'transitions from transfer_in_progress to ancestor_inherited on complete_transfer' do
      namespace.state = described_class::STATES[:transfer_in_progress]
      expect { namespace.complete_transfer(current_user: user) }
        .to change { namespace.state_name }
        .from(:transfer_in_progress)
        .to(:ancestor_inherited)
    end

    it { is_expected.to reject_events :start_transfer, when: :archived }
    it { is_expected.to reject_events :start_transfer, when: :deletion_scheduled }
    it { is_expected.to reject_events :complete_transfer, when: :ancestor_inherited }

    describe 'state values' do
      described_class::STATES.each do |state_name, state_value|
        it { is_expected.to have_state state_name.to_sym, value: state_value }
      end
    end

    describe 'events' do
      describe '#start_transfer' do
        context 'when namespace is in ancestor_inherited state' do
          before do
            namespace.state = described_class::STATES[:ancestor_inherited]
          end

          it 'transitions to transfer_in_progress' do
            expect { namespace.start_transfer(current_user: user) }
              .to change { namespace.state_name }
              .from(:ancestor_inherited)
              .to(:transfer_in_progress)
          end

          it 'updates state_metadata with user and timestamp' do
            freeze_time do
              namespace.start_transfer(current_user: user)

              namespace.namespace_details.reload
              metadata = namespace.namespace_details.state_metadata

              expect(metadata['last_changed_by_user_id']).to eq(user.id)
              expect(metadata['last_updated_at']).to be_present
              expect(metadata['last_error']).to be_nil
            end
          end

          it 'updates state_metadata without user for system-triggered transitions' do
            freeze_time do
              namespace.start_transfer

              namespace.namespace_details.reload
              metadata = namespace.namespace_details.state_metadata

              expect(metadata['last_changed_by_user_id']).to be_nil
              expect(metadata['last_updated_at']).to be_present
              expect(metadata['last_error']).to be_nil
              expect(metadata['correlation_id']).to be_present
            end
          end
        end

        context 'when namespace is not in ancestor_inherited state' do
          before do
            namespace.state = described_class::STATES[:archived]
          end

          it 'does not transition' do
            expect { namespace.start_transfer(current_user: user) }
              .to not_change { namespace.state_name }
          end
        end
      end

      describe '#complete_transfer' do
        context 'when namespace is in transfer_in_progress state' do
          before do
            namespace.state = described_class::STATES[:transfer_in_progress]
          end

          it 'transitions to ancestor_inherited' do
            expect { namespace.complete_transfer(current_user: user) }
              .to change { namespace.state_name }
              .from(:transfer_in_progress)
              .to(:ancestor_inherited)
          end

          it 'updates state_metadata' do
            freeze_time do
              namespace.complete_transfer(current_user: user)

              namespace.namespace_details.reload
              metadata = namespace.namespace_details.state_metadata

              expect(metadata['last_changed_by_user_id']).to eq(user.id)
              expect(metadata['last_updated_at']).to be_present
              expect(metadata['last_error']).to be_nil
            end
          end

          it 'updates state_metadata without user for system-triggered transitions' do
            freeze_time do
              namespace.complete_transfer

              namespace.namespace_details.reload
              metadata = namespace.namespace_details.state_metadata

              expect(metadata['last_changed_by_user_id']).to be_nil
              expect(metadata['last_updated_at']).to be_present
              expect(metadata['last_error']).to be_nil
              expect(metadata['correlation_id']).to be_present
            end
          end
        end

        context 'when namespace is not in transfer_in_progress state' do
          before do
            namespace.state = described_class::STATES[:ancestor_inherited]
          end

          it 'does not transition' do
            expect { namespace.complete_transfer(current_user: user) }
              .to not_change { namespace.state_name }
          end
        end
      end
    end
  end

  describe '#handle_transition_failure' do
    before do
      namespace.state = described_class::STATES[:ancestor_inherited]
    end

    it 'saves error message when transition fails' do
      namespace.errors.add(:state, 'invalid transition')

      transition = Struct.new(:args, :event).new(args: [{ current_user: user }], event: :start_transfer)
      namespace.send(:handle_transition_failure, transition)

      metadata = namespace.namespace_details.reload.state_metadata
      expect(metadata['last_error']).to include('invalid transition')
      expect(metadata['last_changed_by_user_id']).to eq(user.id)
    end

    it 'saves error without current_user' do
      namespace.namespace_details.update!(state_metadata: { last_changed_by_user_id: user.id })
      namespace.errors.add(:state, 'some error')

      transition = Struct.new(:args, :event).new(args: [{}], event: :start_transfer)
      namespace.send(:handle_transition_failure, transition)

      metadata = namespace.namespace_details.reload.state_metadata
      expect(metadata['last_error']).to include('some error')
      expect(metadata['last_changed_by_user_id']).to be_nil
    end

    it 'handles unknown errors when no state errors exist' do
      namespace.namespace_details.update!(state_metadata: {})
      namespace.errors.clear

      expect(namespace.errors[:state]).to be_empty

      transition = Struct.new(:args, :event).new(args: [{ current_user: user }], event: :start_transfer)
      namespace.send(:handle_transition_failure, transition)

      metadata = namespace.namespace_details.reload.state_metadata
      expect(metadata['last_error']).to eq('Unknown transition failure')
    end
  end

  describe 'correlation_id tracking' do
    it 'stores custom correlation_id when provided' do
      custom_correlation_id = 'custom-correlation-id-123'
      namespace.state = described_class::STATES[:ancestor_inherited]
      namespace.start_transfer(current_user: user, correlation_id: custom_correlation_id)

      metadata = namespace.namespace_details.reload.state_metadata
      expect(metadata['correlation_id']).to eq(custom_correlation_id)
    end

    it 'uses current correlation_id when not provided' do
      namespace.state = described_class::STATES[:ancestor_inherited]

      allow(Labkit::Correlation::CorrelationId).to receive(:current_id).and_return('auto-correlation-id')
      namespace.start_transfer(current_user: user)

      metadata = namespace.namespace_details.reload.state_metadata
      expect(metadata['correlation_id']).to eq('auto-correlation-id')
    end

    it 'tracks correlation_id in failure scenarios' do
      custom_correlation_id = 'failure-correlation-id'
      namespace.errors.add(:state, 'test error')

      transition = Struct.new(:args, :event).new(
        args: [{ current_user: user, correlation_id: custom_correlation_id }],
        event: :start_transfer
      )
      namespace.send(:handle_transition_failure, transition)

      metadata = namespace.namespace_details.reload.state_metadata
      expect(metadata['correlation_id']).to eq(custom_correlation_id)
    end
  end

  describe 'logging' do
    it 'logs successful state transitions' do
      namespace.state = described_class::STATES[:ancestor_inherited]

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          message: 'Namespace state transition',
          namespace_id: namespace.id,
          from_state: :ancestor_inherited,
          to_state: :transfer_in_progress,
          event: :start_transfer,
          user_id: user.id,
          correlation_id: be_present
        )
      )

      namespace.start_transfer(current_user: user)
    end

    it 'logs successful state transitions without user' do
      namespace.state = described_class::STATES[:ancestor_inherited]

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          message: 'Namespace state transition',
          namespace_id: namespace.id,
          from_state: :ancestor_inherited,
          to_state: :transfer_in_progress,
          event: :start_transfer,
          user_id: nil,
          correlation_id: be_present
        )
      )

      namespace.start_transfer
    end

    it 'logs failed state transitions' do
      namespace.errors.add(:state, 'test error')

      expect(Gitlab::AppLogger).to receive(:error).with(
        hash_including(
          message: 'Namespace state transition failed',
          namespace_id: namespace.id,
          event: :start_transfer,
          current_state: :ancestor_inherited,
          error: 'test error',
          user_id: user.id,
          correlation_id: be_present
        )
      )

      transition = Struct.new(:args, :event).new(args: [{ current_user: user }], event: :start_transfer)
      namespace.send(:handle_transition_failure, transition)
    end
  end
end
