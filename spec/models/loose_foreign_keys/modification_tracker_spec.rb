# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::ModificationTracker, feature_category: :database do
  subject(:tracker) { described_class.new }

  describe '#over_limit?' do
    it 'is true when deletion max_deletes is exceeded' do
      expect(tracker).to receive(:max_deletes).and_return(5)

      tracker.add_deletions('issues', 10)
      expect(tracker).to be_over_limit
    end

    it 'is false when MAX_DELETES is not exceeded' do
      tracker.add_deletions('issues', 3)

      expect(tracker).not_to be_over_limit
    end

    it 'is true when deletion MAX_UPDATES is exceeded' do
      expect(tracker).to receive(:max_updates).and_return(5)

      tracker.add_updates('issues', 3)
      tracker.add_updates('issues', 4)

      expect(tracker).to be_over_limit
    end

    it 'is false when MAX_UPDATES is not exceeded' do
      tracker.add_updates('projects', 3)

      expect(tracker).not_to be_over_limit
    end

    it 'is true when max runtime is exceeded' do
      monotonic_time_before = 1 # this will be the start time
      monotonic_time_after = 31 # this will be returned when over_limit? is called

      expect(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(
        monotonic_time_before, monotonic_time_after
      )

      tracker

      expect(tracker).to be_over_limit
    end

    it 'is false when max runtime is not exceeded' do
      expect(tracker).not_to be_over_limit
    end
  end

  describe '#add_deletions' do
    it 'increments a Prometheus counter' do
      counter = Gitlab::Metrics.registry.get(:loose_foreign_key_deletions)

      subject.add_deletions(:users, 4)

      expect(counter.get(table: :users)).to eq(4)
    end
  end

  describe '#add_updates' do
    it 'increments a Prometheus counter' do
      counter = Gitlab::Metrics.registry.get(:loose_foreign_key_updates)

      subject.add_updates(:users, 4)

      expect(counter.get(table: :users)).to eq(4)
    end
  end

  describe '#stats' do
    it 'exposes stats' do
      freeze_time do
        tracker
        tracker.add_deletions('issues', 5)
        tracker.add_deletions('issues', 2)
        tracker.add_deletions('projects', 2)

        tracker.add_updates('projects', 3)

        expect(tracker.stats).to eq({
          over_limit: false,
          delete_count_by_table: { 'issues' => 7, 'projects' => 2 },
          update_count_by_table: { 'projects' => 3 },
          delete_count: 9,
          update_count: 3
        })
      end
    end
  end
end
