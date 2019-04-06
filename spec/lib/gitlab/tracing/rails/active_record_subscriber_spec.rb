# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

describe Gitlab::Tracing::Rails::ActiveRecordSubscriber do
  using RSpec::Parameterized::TableSyntax

  describe '.instrument' do
    it 'is unsubscribeable' do
      unsubscribe = described_class.instrument

      expect(unsubscribe).not_to be_nil
      expect { unsubscribe.call }.not_to raise_error
    end
  end

  describe '#notify' do
    subject { described_class.new }
    let(:start) { Time.now }
    let(:finish) { Time.now }

    where(:name, :operation_name, :exception, :connection_id, :cached, :cached_response, :sql) do
      nil         | "active_record:sqlquery"  | nil               | nil | nil   | false | nil
      ""          | "active_record:sqlquery"  | nil               | nil | nil   | false | nil
      "User Load" | "active_record:User Load" | nil               | nil | nil   | false | nil
      "Repo Load" | "active_record:Repo Load" | StandardError.new | nil | nil   | false | nil
      nil         | "active_record:sqlquery"  | nil               | 123 | nil   | false | nil
      nil         | "active_record:sqlquery"  | nil               | nil | false | false | nil
      nil         | "active_record:sqlquery"  | nil               | nil | true  | true  | nil
      nil         | "active_record:sqlquery"  | nil               | nil | true  | true  | "SELECT * FROM users"
    end

    with_them do
      def payload
        {
          name: name,
          exception: exception,
          connection_id: connection_id,
          cached: cached,
          sql: sql
        }
      end

      def expected_tags
        {
          "component" =>        "ActiveRecord",
          "span.kind" =>        "client",
          "db.type" =>          "sql",
          "db.connection_id" => connection_id,
          "db.cached" =>        cached_response,
          "db.statement" =>     sql
        }
      end

      it 'notifies the tracer when the hash contains null values' do
        expect(subject).to receive(:postnotify_span).with(operation_name, start, finish, tags: expected_tags, exception: exception)

        subject.notify(start, finish, payload)
      end

      it 'notifies the tracer when the payload is missing values' do
        expect(subject).to receive(:postnotify_span).with(operation_name, start, finish, tags: expected_tags, exception: exception)

        subject.notify(start, finish, payload.compact)
      end

      it 'does not throw exceptions when with the default tracer' do
        expect { subject.notify(start, finish, payload) }.not_to raise_error
      end
    end
  end
end
