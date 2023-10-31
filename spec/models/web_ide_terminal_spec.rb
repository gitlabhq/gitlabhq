# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebIdeTerminal do
  let(:build) { create(:ci_build) }

  subject { described_class.new(build) }

  it 'returns the show_path of the build' do
    expect(subject.show_path).to end_with("/ide_terminals/#{build.id}")
  end

  it 'returns the retry_path of the build' do
    expect(subject.retry_path).to end_with("/ide_terminals/#{build.id}/retry")
  end

  it 'returns the cancel_path of the build' do
    expect(subject.cancel_path).to end_with("/ide_terminals/#{build.id}/cancel")
  end

  it 'returns the terminal_path of the build' do
    expect(subject.terminal_path).to end_with("/jobs/#{build.id}/terminal.ws")
  end

  it 'returns the proxy_websocket_path of the build' do
    expect(subject.proxy_websocket_path).to end_with("/jobs/#{build.id}/proxy.ws")
  end

  describe 'services' do
    let(:services_with_aliases) do
      {
        services: [{ name: 'postgres', alias: 'postgres' },
                   { name: 'docker:stable-dind', alias: 'docker' }]
      }
    end

    before do
      allow(build).to receive(:options).and_return(config)
    end

    context 'when image does not have an alias' do
      let(:config) do
        { image: 'image:1.0' }.merge(services_with_aliases)
      end

      it 'returns services aliases' do
        expect(subject.services).to eq %w[postgres docker]
      end
    end

    context 'when both image and services have aliases' do
      let(:config) do
        { image: { name: 'image:1.0', alias: 'ruby' } }.merge(services_with_aliases)
      end

      it 'returns all aliases' do
        expect(subject.services).to eq %w[postgres docker ruby]
      end
    end

    context 'when image and services does not have any alias' do
      let(:config) do
        { image: 'image:1.0', services: ['postgres'] }
      end

      it 'returns an empty array' do
        expect(subject.services).to be_empty
      end
    end

    context 'when no image nor services' do
      let(:config) do
        { script: %w[echo] }
      end

      it 'returns an empty array' do
        expect(subject.services).to be_empty
      end
    end
  end
end
