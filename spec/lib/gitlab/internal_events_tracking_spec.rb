# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::InternalEventsTracking, feature_category: :product_analytics do
  before do
    stub_const('TestModule::ClassThatTracks', Class.new do
      include Gitlab::InternalEventsTracking

      def do_it(event_name, args)
        track_internal_event(event_name, **args)
      end
    end)
  end

  describe '.track_internal_event' do
    let(:event_name) { 'do_it' }
    let(:args) { { foo: 'bar', baz: 'qux' } }

    it 'passes event name, args and location to track_event' do
      expect(Gitlab::InternalEvents).to receive(:track_event)
        .with(event_name, category: 'TestModule::ClassThatTracks', **args)

      TestModule::ClassThatTracks.new.do_it(event_name, args)
    end
  end
end
