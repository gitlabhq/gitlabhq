# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Tracking::IncidentManagement do
  describe '.track_from_params' do
    shared_examples 'a tracked event' do |label, value = nil|
      it 'creates the tracking event with the correct details' do
        expect(::Gitlab::Tracking)
          .to receive(:event)
          .with(
            'IncidentManagement::Settings',
            label,
            value || any_args
          )
      end
    end

    after do
      described_class.track_from_params(params)
    end

    context 'known params', :do_not_stub_snowplow_by_default do
      known_params = described_class.tracking_keys

      known_params.each do |key, values|
        context "param #{key}" do
          let(:params) { { key => '1' } }

          it_behaves_like 'a tracked event', "enabled_#{known_params[key][:name]}"
        end
      end

      context 'different input values' do
        shared_examples 'the correct prefixed event name' do |input, enabled|
          let(:params) { { issue_template_key: input } }

          it 'matches' do
            expect(::Gitlab::Tracking)
            .to receive(:event)
            .with(
              anything,
              "#{enabled}_issue_template_on_alerts",
              anything
            )
          end
        end

        it_behaves_like 'the correct prefixed event name', 1,          'enabled'
        it_behaves_like 'the correct prefixed event name', '1',        'enabled'
        it_behaves_like 'the correct prefixed event name', 'template', 'enabled'
        it_behaves_like 'the correct prefixed event name', '',         'disabled'
        it_behaves_like 'the correct prefixed event name', nil,        'disabled'
      end

      context 'param with label' do
        let(:params) { { issue_template_key: '1' } }

        it_behaves_like 'a tracked event', "enabled_issue_template_on_alerts", { label: 'Template name', property: '1' }
      end

      context 'param without label' do
        let(:params) { { create_issue: '1' } }

        it_behaves_like 'a tracked event', "enabled_issue_auto_creation_on_alerts"
      end
    end

    context 'unknown params' do
      let(:params) { { 'unknown' => '1' } }

      it 'does not create the tracking event' do
        expect(::Gitlab::Tracking)
          .not_to receive(:event)
      end
    end
  end
end
