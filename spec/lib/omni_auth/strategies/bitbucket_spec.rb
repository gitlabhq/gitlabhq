# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniAuth::Strategies::Bitbucket do
  subject { described_class.new({}) }

  describe '#callback_url' do
    let(:base_url) { 'https://example.com' }

    context 'when script name is not present' do
      it 'has the correct default callback path' do
        allow(subject).to receive(:full_host) { base_url }
        allow(subject).to receive(:script_name).and_return('')
        allow(subject).to receive(:query_string).and_return('')
        expect(subject.callback_url).to eq("#{base_url}/users/auth/bitbucket/callback")
      end
    end

    context 'when script name is present' do
      it 'sets the callback path with script_name' do
        allow(subject).to receive(:full_host) { base_url }
        allow(subject).to receive(:script_name).and_return('/v1')
        allow(subject).to receive(:query_string).and_return('')
        expect(subject.callback_url).to eq("#{base_url}/v1/users/auth/bitbucket/callback")
      end
    end
  end
end
