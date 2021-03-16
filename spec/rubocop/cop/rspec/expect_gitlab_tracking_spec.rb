# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/rspec/expect_gitlab_tracking'

RSpec.describe RuboCop::Cop::RSpec::ExpectGitlabTracking do
  let(:source_file) { 'spec/foo_spec.rb' }

  subject(:cop) { described_class.new }

  good_samples = [
    'expect_snowplow_event(category: nil, action: nil)',
    'expect_snowplow_event(category: "EventCategory", action: "event_action")',
    'expect_snowplow_event(category: "EventCategory", action: "event_action", label: "label", property: "property")',
    'expect_no_snowplow_event'
  ]

  bad_samples = [
    'expect(Gitlab::Tracking).to receive(:event)',
    'expect(Gitlab::Tracking).to_not receive(:event)',
    'expect(Gitlab::Tracking).not_to receive(:event)',
    'expect(Gitlab::Tracking).to_not receive(:event).with("EventCategory", "event_action")',
    'expect(Gitlab::Tracking).not_to receive(:event).with("EventCategory", "event_action")',
    'expect(Gitlab::Tracking).to receive(:event).with("EventCategory", "event_action", label: "label", property: "property")',
    'expect(Gitlab::Tracking).to have_received(:event).with("EventCategory", "event_action")',
    'expect(Gitlab::Tracking).to_not have_received(:event).with("EventCategory", "event_action")',
    'expect(Gitlab::Tracking).not_to have_received(:event).with("EventCategory", "event_action")',
    'allow(Gitlab::Tracking).to receive(:event).and_call_original'
  ]

  good_samples.each do |good|
    context "good: #{good}" do
      it 'does not register an offense' do
        expect_no_offenses(good)
      end
    end
  end

  bad_samples.each do |bad|
    context "bad: #{bad}" do
      it 'registers an offense' do
        expect_offense(<<~CODE, node: bad)
          %{node}
          ^{node} Do not expect directly on `Gitlab::Tracking#event`[...]
        CODE
      end
    end
  end
end
