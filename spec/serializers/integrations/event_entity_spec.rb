# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::EventEntity, feature_category: :integrations do
  let(:request) { EntityRequest.new(integration: integration) }

  subject { described_class.new(event, request: request, integration: integration).as_json }

  before do
    allow(request).to receive(:integration).and_return(integration)
  end

  describe '#as_json' do
    context 'with integration without fields' do
      let(:integration) { create(:emails_on_push_integration, push_events: true) }
      let(:event) { 'push' }

      it 'exposes correct attributes' do
        expect(subject[:description]).to eq('Trigger event for pushes to the repository.')
        expect(subject[:name]).to eq('push_events')
        expect(subject[:title]).to eq('Push')
        expect(subject[:value]).to be(true)
      end
    end

    context 'with integration with fields' do
      let(:integration) { create(:integrations_slack, note_events: false, note_channel: 'note-channel') }
      let(:event) { 'note' }

      it 'exposes correct attributes' do
        expect(subject[:description]).to eq('Trigger event for new comments.')
        expect(subject[:name]).to eq('note_events')
        expect(subject[:title]).to eq('Note')
        expect(subject[:value]).to eq(false)
        expect(subject[:field][:name]).to eq('note_channel')
        expect(subject[:field][:value]).to eq('note-channel')
        expect(subject[:field][:placeholder]).to eq('#general, #development')
      end
    end

    context 'with integration with fields when channels are masked' do
      let(:integration) { create(:integrations_slack, note_events: false, note_channel: 'note-channel') }
      let(:event) { 'note' }

      before do
        allow(integration).to receive(:mask_configurable_channels?).and_return(true)
      end

      it 'exposes correct attributes' do
        expect(subject[:description]).to eq('Trigger event for new comments.')
        expect(subject[:name]).to eq('note_events')
        expect(subject[:title]).to eq('Note')
        expect(subject[:value]).to eq(false)
        expect(subject[:field][:name]).to eq('note_channel')
        expect(subject[:field][:value]).to eq(Integrations::Base::ChatNotification::SECRET_MASK)
        expect(subject[:field][:placeholder]).to eq('#general, #development')
      end
    end
  end
end
