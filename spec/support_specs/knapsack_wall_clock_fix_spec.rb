# frozen_string_literal: true

require 'fast_spec_helper'
require 'knapsack'
require 'rspec/core/formatters/base_formatter'

require_relative '../support/knapsack_wall_clock_fix'

RSpec.describe Support::KnapsackWallClockFix, feature_category: :tooling do # rubocop:disable RSpec/SpecFilePathFormat -- support_specs is the conventional location for specs testing spec/support files
  let(:output) { StringIO.new }
  let(:formatter) { described_class.new(output) }
  let(:tracker) { Knapsack.tracker }

  let(:example_group_stub) { Struct.new(:metadata, keyword_init: true) }
  let(:group_notification_stub) { Struct.new(:group, keyword_init: true) }

  def notification_for(file_path)
    group = example_group_stub.new(metadata: { file_path: file_path })
    group_notification_stub.new(group: group)
  end

  before do
    tracker.reset!

    tracker.test_files_with_time['spec/models/user_spec.rb'] = 10.0
    tracker.test_files_with_time['spec/migrations/some_migration_spec.rb'] = 5.0

    formatter.start(double)
  end

  describe '#example_group_finished' do
    it 'overwrites knapsack tracked time with wall-clock duration for top-level groups' do
      notification = notification_for('./spec/migrations/some_migration_spec.rb')

      formatter.example_group_started(notification)

      sleep 0.05

      formatter.example_group_finished(notification)

      recorded_time = tracker.test_files_with_time['spec/migrations/some_migration_spec.rb']
      expect(recorded_time).to be >= 0.05
      expect(recorded_time).not_to eq(5.0)
    end

    it 'does not overwrite time for nested groups' do
      outer = notification_for('./spec/models/user_spec.rb')
      inner = notification_for('./spec/models/user_spec.rb')

      formatter.example_group_started(outer)
      formatter.example_group_started(inner)
      formatter.example_group_finished(inner)

      expect(tracker.test_files_with_time['spec/models/user_spec.rb']).to eq(10.0)
    end

    it 'overwrites time only when the outermost group finishes' do
      outer = notification_for('./spec/models/user_spec.rb')
      inner = notification_for('./spec/models/user_spec.rb')

      formatter.example_group_started(outer)
      formatter.example_group_started(inner)
      formatter.example_group_finished(inner)
      formatter.example_group_finished(outer)

      recorded_time = tracker.test_files_with_time['spec/models/user_spec.rb']
      expect(recorded_time).not_to eq(10.0)
      expect(recorded_time).to be >= 0.0
    end

    it 'tracks multiple spec files independently' do
      first = notification_for('./spec/models/user_spec.rb')
      second = notification_for('./spec/migrations/some_migration_spec.rb')

      formatter.example_group_started(first)
      sleep 0.02
      formatter.example_group_finished(first)

      formatter.example_group_started(second)
      sleep 0.04
      formatter.example_group_finished(second)

      user_time = tracker.test_files_with_time['spec/models/user_spec.rb']
      migration_time = tracker.test_files_with_time['spec/migrations/some_migration_spec.rb']

      expect(user_time).to be >= 0.02
      expect(migration_time).to be >= 0.04
      expect(migration_time).to be > user_time
    end
  end
end
