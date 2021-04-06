# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceEventEntity do
  let(:request) { double('request') }

  subject { described_class.new(event, request: request, service: service).as_json }

  before do
    allow(request).to receive(:service).and_return(service)
  end

  describe '#as_json' do
    context 'service without fields' do
      let(:service) { create(:emails_on_push_service, push_events: true) }
      let(:event) { 'push' }

      it 'exposes correct attributes' do
        expect(subject[:description]).to eq('Trigger event for pushes to the repository.')
        expect(subject[:name]).to eq('push_events')
        expect(subject[:title]).to eq('push')
        expect(subject[:value]).to be(true)
      end
    end

    context 'service with fields' do
      let(:service) { create(:slack_service, note_events: false, note_channel: 'note-channel') }
      let(:event) { 'note' }

      it 'exposes correct attributes' do
        expect(subject[:description]).to eq('Trigger event for new comments.')
        expect(subject[:name]).to eq('note_events')
        expect(subject[:title]).to eq('note')
        expect(subject[:value]).to eq(false)
        expect(subject[:field][:name]).to eq('note_channel')
        expect(subject[:field][:value]).to eq('note-channel')
      end
    end
  end
end
