# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::ErrorEvent, type: :model do
  let_it_be(:event) { create(:error_tracking_error_event) }

  describe 'relationships' do
    it { is_expected.to belong_to(:error) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:occurred_at) }
  end

  describe '#stacktrace' do
    it 'generates a correct stacktrace in expected format' do
      expected_context = [
        [132, "          end\n"],
        [133, "\n"],
        [134, "          begin\n"],
        [135, "            block.call(work, *extra)\n"],
        [136, "          rescue Exception => e\n"],
        [137, "            STDERR.puts \"Error reached top of thread-pool: #\{e.message\} (#\{e.class\})\"\n"],
        [138, "          end\n"]
      ]

      expected_entry = {
        'lineNo' => 135,
        'context' => expected_context,
        'filename' => 'puma/thread_pool.rb',
        'function' => 'block in spawn_thread',
        'colNo' => 0
      }

      expect(event.stacktrace).to be_kind_of(Array)
      expect(event.stacktrace.first).to eq(expected_entry)
    end
  end

  describe '#to_sentry_error_event' do
    it { expect(event.to_sentry_error_event).to be_kind_of(Gitlab::ErrorTracking::ErrorEvent) }
  end
end
