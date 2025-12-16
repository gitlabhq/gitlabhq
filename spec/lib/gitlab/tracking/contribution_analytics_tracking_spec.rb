# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::ContributionAnalyticsTracking, feature_category: :service_ping do
  let(:user) { build_stubbed(:user) }
  let(:meta) { { foo: 'bar' } }
  let(:fingerprint) { 'abc123' }
  let(:label) { :create }
  let(:event_name) { 'performed_wiki_action' }

  describe '.track_event' do
    it 'delegates to EventCreateService#wiki_event' do
      service = instance_double(EventCreateService)
      expect(EventCreateService).to receive(:new).and_return(service)
      expect(service).to receive(:wiki_event).with(meta, user, label, fingerprint)

      described_class.track_event(event_name, user: user, label: label, meta: meta, fingerprint: fingerprint)
    end
  end
end
