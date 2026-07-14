# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/event_store_cloud_event_inheritance'

RSpec.describe RuboCop::Cop::Gitlab::EventStoreCloudEventInheritance, feature_category: :tooling do
  let(:msg) do
    'Inherit from `Gitlab::EventStore::CloudEvent` (or a descendant) instead of ' \
      '`Gitlab::EventStore::Event`. ' \
      'All events must comply with the CloudEvents spec. ' \
      'See https://docs.gitlab.com/ee/development/eventstore/'
  end

  context 'when a class inherits from Gitlab::EventStore::Event' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class MyEvent < Gitlab::EventStore::Event
                        ^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
          def schema
            { 'type' => 'object' }
          end
        end
      RUBY
    end
  end

  context 'when a class inherits from ::Gitlab::EventStore::Event' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class MyEvent < ::Gitlab::EventStore::Event
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
          def schema
            { 'type' => 'object' }
          end
        end
      RUBY
    end
  end

  context 'when a class named CloudEvent inherits from Event but is not in cloud_event.rb' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
      class CloudEvent < Gitlab::EventStore::Event
                         ^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      end
      RUBY
    end
  end

  context 'when a class inherits from ::Gitlab::EventStore::Event inside a module' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        module Foo
          class MyEvent < ::Gitlab::EventStore::Event
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
            def schema
              { 'type' => 'object' }
            end
          end
        end
      RUBY
    end
  end

  context 'when a class inherits from Gitlab::EventStore::CloudEvent' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class MyEvent < Gitlab::EventStore::CloudEvent
          event_category :my_domain
          event_type :my_event

          def data_schema
            { 'type' => 'object' }
          end
        end
      RUBY
    end
  end

  context 'when a class inherits from ::Gitlab::EventStore::CloudEvent' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class MyEvent < ::Gitlab::EventStore::CloudEvent
          event_category :my_domain
          event_type :my_event

          def data_schema
            { 'type' => 'object' }
          end
        end
      RUBY
    end
  end

  context 'when a class inherits from a custom base class' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class MyEvent < WorkItems::BaseEvent
        end
      RUBY
    end
  end

  context 'when a class does not inherit from any EventStore class' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class MyService < BaseService
        end
      RUBY
    end
  end
end
