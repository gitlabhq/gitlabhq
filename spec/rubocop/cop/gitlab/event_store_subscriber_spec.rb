# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/gitlab/event_store_subscriber'

RSpec.describe RuboCop::Cop::Gitlab::EventStoreSubscriber do
  context 'when an event store subscriber overrides #perform' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class SomeWorker
          include Gitlab::EventStore::Subscriber

          def perform(*args)
          ^^^^^^^^^^^^^^^^^^ Do not override `perform` in a `Gitlab::EventStore::Subscriber`.
          end

          def handle_event(event); end
        end
      RUBY
    end
  end

  context 'when an event store subscriber does not override #perform' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class SomeWorker
          include Gitlab::EventStore::Subscriber

          def handle_event(event); end
        end
      RUBY
    end
  end

  context 'when an event store subscriber does not implement #handle_event' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class SomeWorker
          include Gitlab::EventStore::Subscriber
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ A `Gitlab::EventStore::Subscriber` must implement `#handle_event(event)`.
        end
      RUBY
    end
  end

  context 'when a Sidekiq worker overrides #perform' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class SomeWorker
          include ApplicationWorker

          def perform(*args); end
        end
      RUBY
    end
  end

  context 'when a Sidekiq worker implements #handle_event' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class SomeWorker
          include ApplicationWorker

          def handle_event(event); end
        end
      RUBY
    end
  end

  context 'a non worker class' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class Model < ApplicationRecord
          include ActiveSupport::Concern
        end
      RUBY
    end
  end
end
