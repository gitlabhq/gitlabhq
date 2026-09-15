# frozen_string_literal: true

require 'spec_helper'

# Regression coverage for https://gitlab.com/gitlab-org/gitlab/-/work_items/608175.
# auto_explain reports "Query Text" from debug_query_string, which for a simple
# query message is the whole message. Batching ~1,100 DELETEs into one message
# therefore logs the full batch once per statement, so log volume grows with the
# square of the batch size. CI runs auto_explain with log_min_duration=0.
RSpec.describe 'Batched DatabaseCleaner deletion and auto_explain', :delete, feature_category: :database do
  let(:setting) { 'auto_explain.log_min_duration' }
  let(:connection) { ApplicationRecord.connection }

  def threshold
    connection.select_value("SELECT current_setting('#{setting}', true)")
  end

  # Records the threshold in effect while the batched sweep runs.
  def thresholds_during_sweep
    observed = []

    allow(connection).to receive(:execute).and_wrap_original do |original, sql|
      observed << threshold if sql.start_with?('DELETE FROM')

      original.call(sql)
    end

    delete_from_all_tables!(except: deletion_except_tables)

    observed
  end

  context 'when auto_explain is loaded' do
    before do
      connection.execute("LOAD '#{setting.split('.').first}'")
      connection.execute("SET #{setting} = 0")
    end

    after do
      connection.execute("SET #{setting} = -1")
    end

    it 'disables auto_explain while the batch runs', :aggregate_failures do
      observed = thresholds_during_sweep

      expect(observed).not_to be_empty
      expect(observed).to all(eq('-1'))
    end

    it 'restores the previous threshold afterwards' do
      delete_from_all_tables!(except: deletion_except_tables)

      expect(threshold).to eq('0')
    end
  end

  context 'when auto_explain is not loaded' do
    # current_setting(..., true) returns nil for an unloaded extension. LOAD
    # persists for the whole connection, so simulate the unloaded reading
    # rather than depending on which specs already ran on this connection.
    before do
      allow(connection).to receive(:select_value).and_wrap_original do |original, sql|
        sql.include?(setting) ? nil : original.call(sql)
      end
    end

    it 'cleans without touching the setting' do
      # The cleanup issues many unrelated execute calls, so let them through:
      # a bare negative expectation would reject them as unexpected arguments.
      allow(connection).to receive(:execute).and_call_original
      expect(connection).not_to receive(:execute).with(a_string_matching(/SET #{Regexp.escape(setting)}/))

      expect { delete_from_all_tables!(except: deletion_except_tables) }.not_to raise_error
    end
  end
end
