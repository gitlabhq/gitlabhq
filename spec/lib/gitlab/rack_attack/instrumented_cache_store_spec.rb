# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack::InstrumentedCacheStore do
  using RSpec::Parameterized::TableSyntax

  let(:store) { ::ActiveSupport::Cache::NullStore.new }

  subject { described_class.new(upstream_store: store)}

  where(:operation, :params, :test_proc) do
    :fetch | [:key] | ->(s) { s.fetch(:key) }
    :read | [:key] | ->(s) { s.read(:key) }
    :read_multi | [:key_1, :key_2, :key_3] | ->(s) { s.read_multi(:key_1, :key_2, :key_3) }
    :write_multi | [{ key_1: 1, key_2: 2, key_3: 3 }] | ->(s) { s.write_multi(key_1: 1, key_2: 2, key_3: 3) }
    :fetch_multi | [:key_1, :key_2, :key_3] | ->(s) { s.fetch_multi(:key_1, :key_2, :key_3) {} }
    :write | [:key, :value, { option_1: 1 }] | ->(s) { s.write(:key, :value, option_1: 1) }
    :delete | [:key] | ->(s) { s.delete(:key) }
    :exist? | [:key, { option_1: 1 }] | ->(s) { s.exist?(:key, option_1: 1) }
    :delete_matched | [/^key$/, { option_1: 1 }] | ->(s) { s.delete_matched(/^key$/, option_1: 1 ) }
    :increment | [:key, 1] | ->(s) { s.increment(:key, 1) }
    :decrement | [:key, 1] | ->(s) { s.decrement(:key, 1) }
    :cleanup | [] | ->(s) { s.cleanup }
    :clear | [] | ->(s) { s.clear }
  end

  with_them do
    it 'publishes a notification' do
      event = nil

      begin
        subscriber = ActiveSupport::Notifications.subscribe("redis.rack_attack") do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
        end

        test_proc.call(subject)
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end

      expect(event).not_to be_nil
      expect(event.name).to eq("redis.rack_attack")
      expect(event.duration).to be_a(Float).and(be > 0.0)
      expect(event.payload[:operation]).to eql(operation)
    end

    it 'publishes a notification even if the cache store returns an error' do
      allow(store).to receive(operation).and_raise('Something went wrong')

      event = nil
      exception = nil

      begin
        subscriber = ActiveSupport::Notifications.subscribe("redis.rack_attack") do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
        end

        begin
          test_proc.call(subject)
        rescue StandardError => e
          exception = e
        end
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end

      expect(event).not_to be_nil
      expect(event.name).to eq("redis.rack_attack")
      expect(event.duration).to be_a(Float).and(be > 0.0)
      expect(event.payload[:operation]).to eql(operation)

      expect(exception).not_to be_nil
      expect(exception.message).to eql('Something went wrong')
    end

    it 'delegates to the upstream store' do
      allow(store).to receive(operation).and_call_original

      if params.empty?
        expect(store).to receive(operation).with(no_args)
      else
        expect(store).to receive(operation).with(*params)
      end

      test_proc.call(subject)
    end
  end
end
