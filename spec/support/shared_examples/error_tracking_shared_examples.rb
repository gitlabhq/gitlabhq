# frozen_string_literal: true

RSpec.shared_examples 'setting sentry error data' do
  it 'sets the sentry error data correctly' do
    aggregate_failures 'testing the sentry error is correct' do
      expect(error['id']).to eq sentry_error.to_global_id.to_s
      expect(error['sentryId']).to eq sentry_error.id.to_s
      expect(error['status']).to eq sentry_error.status.upcase
      expect(error['firstSeen']).to eq sentry_error.first_seen
      expect(error['lastSeen']).to eq sentry_error.last_seen
    end
  end
end

RSpec.shared_examples 'setting stack trace error' do
  it 'sets the stack trace data correctly' do
    aggregate_failures 'testing the stack trace is correct' do
      expect(stack_trace_data['dateReceived']).to eq(sentry_stack_trace.date_received)
      expect(stack_trace_data['issueId']).to eq(sentry_stack_trace.issue_id)
      expect(stack_trace_data['stackTraceEntries']).to be_an_instance_of(Array)
      expect(stack_trace_data['stackTraceEntries'].size).to eq(sentry_stack_trace.stack_trace_entries.size)
    end
  end

  it 'sets the stack trace entry data correctly' do
    aggregate_failures 'testing the stack trace entry is correct' do
      stack_trace_entry = stack_trace_data['stackTraceEntries'].first
      model_entry = sentry_stack_trace.stack_trace_entries.first

      expect(stack_trace_entry['function']).to eq model_entry['function']
      expect(stack_trace_entry['col']).to eq model_entry['colNo']
      expect(stack_trace_entry['line']).to eq model_entry['lineNo'].to_s
      expect(stack_trace_entry['fileName']).to eq model_entry['filename']
    end
  end
end
