# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::EventParams do
  describe '.parse_event_params' do
    subject { described_class.parse_event_params(raw_event) }

    let(:raw_event) { Gitlab::Json.parse(fixture_file('product_analytics/event.json')) }

    it 'extracts all params from raw event' do
      expected_params = {
        project_id: '1',
        platform: 'web',
        name_tracker: 'sp',
        v_tracker: 'js-2.14.0',
        event_id: 'fbf14096-74ee-47e4-883c-8a0d6cb72e37',
        domain_userid: '79543c31-cfc3-4479-a737-fafb9333c8ba',
        domain_sessionid: '54f6d3f3-f4f9-4fdc-87e0-a2c775234c1b',
        domain_sessionidx: 4,
        page_url: 'http://example.com/products/1',
        page_referrer: 'http://example.com/products/1',
        br_lang: 'en-US',
        br_cookies: true,
        os_timezone: 'America/Los_Angeles',
        doc_charset: 'UTF-8',
        se_category: 'category',
        se_action: 'action',
        se_label: 'label',
        se_property: 'property',
        se_value: 12.34
      }

      expect(subject).to include(expected_params)
    end
  end

  describe '.has_required_params?' do
    subject { described_class.has_required_params?(params) }

    context 'aid and eid are present' do
      let(:params) { { 'aid' => 1, 'eid' => 2 } }

      it { expect(subject).to be_truthy }
    end

    context 'aid and eid are missing' do
      let(:params) { {} }

      it { expect(subject).to be_falsey }
    end

    context 'eid is missing' do
      let(:params) { { 'aid' => 1 } }

      it { expect(subject).to be_falsey }
    end
  end
end
