# frozen_string_literal: true

require 'spec_helper'

describe WikiPages::BaseService do
  let(:project) { double('project') }
  let(:user) { double('user') }

  subject(:service) { described_class.new(project, user, {}) }

  describe '#increment_usage' do
    counter = Gitlab::UsageDataCounters::WikiPageCounter
    error = counter::UnknownEvent

    it 'raises an error on unknown events' do
      expect { subject.send(:increment_usage, :bad_event) }.to raise_error error
    end

    context 'the event is valid' do
      counter::KNOWN_EVENTS.each do |e|
        it "updates the #{e} counter" do
          expect { subject.send(:increment_usage, e) }.to change { counter.read(e) }
        end
      end
    end
  end
end
