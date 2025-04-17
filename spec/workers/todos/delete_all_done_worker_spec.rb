# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::DeleteAllDoneWorker, feature_category: :notifications do
  let(:time) { 1.day.ago.utc.to_datetime }

  context 'when lease is not taken' do
    let_it_be(:user) { create(:user) }
    let_it_be(:user2) { create(:user) }
    let_it_be(:todo1) { create(:todo, :done, user: user, updated_at: 3.days.ago) }
    let_it_be(:todo2) { create(:todo, :done, user: user, updated_at: 4.days.ago) }
    let_it_be(:todo3) { create(:todo, :done, user: user) }
    let_it_be(:todo4) { create(:todo, :done, user: user2) }
    let_it_be(:todo5) { create(:todo, user: user) }

    it 'removes todos for passed user' do
      expect { described_class.new.perform(user.id, time.to_s) }
        .to change { Todo.count }.from(5).to(3)

      expect { todo1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { todo2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'does not remove todos for other users' do
      described_class.new.perform(user.id, time.to_s)

      expect { todo4.reload }.not_to raise_error
    end

    it 'does not remove pending todos' do
      described_class.new.perform(user.id, time.to_s)

      expect { todo5.reload }.not_to raise_error
    end

    it 'does not remove todos updated after passed time' do
      described_class.new.perform(user.id, time.to_s)

      expect { todo3.reload }.not_to raise_error
    end

    context 'when there is more todos to delete than batch size' do
      before do
        2.times do
          create(:todo, :done, user: user, updated_at: 3.days.ago)
        end
      end

      it 'removes todos for passed user', :use_sql_query_cache do
        stub_const("#{described_class.name}::BATCH_DELETE_SIZE", 3)

        queries_count = ActiveRecord::QueryRecorder.new do
          described_class.new.perform(user.id, time.to_s)
        end

        expect(queries_count.count).to eq(9)

        expect { todo1.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { todo2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'for runtime limit' do
      before do
        stub_const("#{described_class}::BATCH_DELETE_SIZE", 1)
      end

      context 'when runtime limit is reached' do
        before do
          allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |runtime_limiter|
            allow(runtime_limiter).to receive(:over_time?).and_return(false, true)
          end
        end

        it 'schedules the worker in 2 minutes with the last processed user id value as the cursor', :freeze_time do
          expect(described_class).to receive(:perform_in).with(2.minutes, user.id, time)

          described_class.new.perform(user.id, time.to_s)
        end
      end

      context 'when runtime limit is not reached' do
        it 'does not schedule the worker' do
          expect(described_class).not_to receive(:perform_in)

          described_class.new.perform(user.id, time.to_s)
        end
      end
    end
  end

  context 'when lease is taken' do
    include ExclusiveLeaseHelpers

    let(:lease_key) { "#{described_class.name.underscore}_100" }

    before do
      stub_exclusive_lease_taken(lease_key)
    end

    it 'does not permit parallel execution on the same project' do
      expect { described_class.new.perform(100, time.to_s) }
        .to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
    end
  end
end
