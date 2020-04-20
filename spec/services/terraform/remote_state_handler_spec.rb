# frozen_string_literal: true

require 'spec_helper'

describe Terraform::RemoteStateHandler do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

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
      end
    end
  end

  describe '#create_or_find!' do
    it 'requires passing a state name' do
      handler = described_class.new(project, user)

      expect { handler.create_or_find! }.to raise_error(ArgumentError)
    end

    it 'allows to create states with same name in different projects' do
      project_b =  create(:project)

      state_a = described_class.new(project, user, name: 'my-state').create_or_find!
      state_b = described_class.new(project_b, user, name: 'my-state').create_or_find!

      expect(state_a).to be_persisted
      expect(state_b).to be_persisted
      expect(state_a.id).not_to eq state_b.id
    end

    it 'loads the same state upon subsequent call in the project scope' do
      state_a = described_class.new(project, user, name: 'my-state').create_or_find!
      state_b = described_class.new(project, user, name: 'my-state').create_or_find!

      expect(state_a).to be_persisted
      expect(state_a.id).to eq state_b.id
    end
  end

  context 'when state locking is not being used' do
    subject { described_class.new(project, user, name: 'my-state') }

    describe '#handle_with_lock' do
      it 'allows to modify a state using database locking' do
        state = subject.handle_with_lock do |state|
          state.name = 'updated-name'
        end

        expect(state.name).to eq 'updated-name'
      end

      it 'returns the state object itself' do
        state = subject.create_or_find!

        expect(state.name).to eq 'my-state'
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
      it 'handles a locked state using exclusive read lock' do
        handler = described_class
          .new(project, user, name: 'new-state', lock_id: 'abc-abc')

        handler.lock!

        state = handler.handle_with_lock do |state|
          state.name = 'new-name'
        end

        expect(state.name).to eq 'new-name'
      end
    end

    it 'raises exception if lock has not been acquired before' do
      handler = described_class
        .new(project, user, name: 'new-state', lock_id: 'abc-abc')

      expect { handler.handle_with_lock }
        .to raise_error(described_class::StateLockedError)
    end

    describe '#lock!' do
      it 'allows to lock state if it does not exist yet' do
        handler = described_class.new(project, user, name: 'new-state', lock_id: 'abc-abc')

        state = handler.lock!

        expect(state).to be_persisted
        expect(state.name).to eq 'new-state'
      end

      it 'allows to lock state if it exists and is not locked' do
        state = described_class.new(project, user, name: 'new-state').create_or_find!
        handler = described_class.new(project, user, name: 'new-state', lock_id: 'abc-abc')

        handler.lock!

        expect(state.reload.lock_xid).to eq 'abc-abc'
        expect(state).to be_locked
      end

      it 'raises an exception when trying to unlocked state locked by someone else' do
        described_class.new(project, user, name: 'new-state', lock_id: 'abc-abc').lock!

        handler = described_class.new(project, user, name: 'new-state', lock_id: '12a-23f')

        expect { handler.lock! }.to raise_error(described_class::StateLockedError)
      end
    end
  end
end
