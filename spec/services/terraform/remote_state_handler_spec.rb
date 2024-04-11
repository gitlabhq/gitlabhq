# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::RemoteStateHandler, feature_category: :infrastructure_as_code do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }

  let_it_be(:user) { maintainer }

  describe '#find_with_lock' do
    context 'without a state name' do
      subject { described_class.new(project, user) }

      it 'raises an exception' do
        expect { subject.find_with_lock }.to raise_error(ArgumentError)
      end
    end

    context 'with a state name' do
      subject { described_class.new(project, user, name: 'state') }

      context 'with no matching state' do
        it 'raises an exception' do
          expect { subject.find_with_lock }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'with a matching state' do
        let!(:state) { create(:terraform_state, project: project, name: 'state') }

        it 'returns the state' do
          expect(subject.find_with_lock).to eq(state)
        end

        context 'with a state scheduled for deletion' do
          let!(:state) { create(:terraform_state, :deletion_in_progress, project: project, name: 'state') }

          it 'raises an exception' do
            expect { subject.find_with_lock }.to raise_error(described_class::StateDeletedError)
          end
        end
      end
    end
  end

  context 'when state locking is not being used' do
    subject { described_class.new(project, user, name: 'my-state') }

    describe '#handle_with_lock' do
      it 'allows to modify a state using database locking' do
        record = nil
        subject.handle_with_lock do |state|
          record = state
          state.name = 'updated-name'
        end

        expect(record.reload.name).to eq 'updated-name'
      end

      it 'returns nil' do
        expect(subject.handle_with_lock).to be_nil
      end
    end

    describe '#lock!' do
      it 'raises an error' do
        expect { subject.lock! }.to raise_error(ArgumentError)
      end
    end
  end

  context 'when using locking' do
    describe '#handle_with_lock' do
      subject(:handler) { described_class.new(project, user, name: 'new-state', lock_id: 'abc-abc') }

      it 'handles a locked state using exclusive read lock' do
        handler.lock!

        record = nil
        handler.handle_with_lock do |state|
          record = state
          state.name = 'new-name'
        end

        expect(record.reload.name).to eq 'new-name'
        expect(record.reload.project).to eq project
      end

      it 'raises exception if lock has not been acquired before' do
        expect { handler.handle_with_lock }
          .to raise_error(described_class::StateLockedError)
      end

      it 'raises an exception if the state is scheduled for deletion' do
        create(:terraform_state, :deletion_in_progress, project: project, name: 'new-state')

        expect { handler.handle_with_lock }
          .to raise_error(described_class::StateDeletedError)
      end

      context 'user does not have permission to modify state' do
        let(:user) { developer }

        it 'raises an exception' do
          expect { handler.handle_with_lock }
            .to raise_error(described_class::UnauthorizedError)
        end
      end
    end

    describe '#lock!' do
      let(:lock_id) { 'abc-abc' }

      subject(:handler) do
        described_class.new(
          project,
          user,
          name: 'new-state',
          lock_id: lock_id
        )
      end

      it 'allows to lock state if it does not exist yet' do
        state = handler.lock!

        expect(state).to be_persisted
        expect(state.name).to eq 'new-state'
      end

      it 'allows to lock state if it exists and is not locked' do
        state = create(:terraform_state, project: project, name: 'new-state')

        handler.lock!

        expect(state.reload.lock_xid).to eq lock_id
        expect(state).to be_locked
      end

      it 'raises an exception when trying to unlocked state locked by someone else' do
        described_class.new(project, user, name: 'new-state', lock_id: '12a-23f').lock!

        expect { handler.lock! }.to raise_error(described_class::StateLockedError)
      end

      it 'raises an exception when the state exists and is scheduled for deletion' do
        create(:terraform_state, :deletion_in_progress, project: project, name: 'new-state')

        expect { handler.lock! }.to raise_error(described_class::StateDeletedError)
      end
    end

    describe '#unlock!' do
      let_it_be(:state) { create(:terraform_state, :locked, project: project, name: 'new-state', lock_xid: 'abc-abc') }

      let(:lock_id) { state.lock_xid }

      subject(:handler) do
        described_class.new(
          project,
          user,
          name: state.name,
          lock_id: lock_id
        )
      end

      it 'unlocks the state' do
        state = handler.unlock!

        expect(state.lock_xid).to be_nil
      end

      context 'with no lock ID (force-unlock)' do
        let(:lock_id) {}

        it 'unlocks the state' do
          state = handler.unlock!

          expect(state.lock_xid).to be_nil
        end
      end

      context 'with different lock ID' do
        let(:lock_id) { 'other' }

        it 'raises an exception' do
          expect { handler.unlock! }
            .to raise_error(described_class::StateLockedError)
        end
      end

      context 'with a state scheduled for deletion' do
        it 'raises an exception' do
          state.update!(deleted_at: Time.current)

          expect { handler.unlock! }
            .to raise_error(described_class::StateDeletedError)
        end
      end
    end
  end
end
