# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ChatMessage::BaseMessage do
  let(:base_message) { described_class.new(args) }
  let(:args) { { project_url: 'https://gitlab-domain.com' } }

  describe '#fallback' do
    subject { base_message.fallback }

    before do
      allow(base_message).to receive(:message).and_return(message)
    end

    context 'without relative links' do
      let(:message) { 'Just another *markdown* message' }

      it { is_expected.to eq(message) }
    end

    context 'with relative links' do
      let(:message) { 'Check this out ![Screenshot1](/uploads/Screenshot1.png)' }

      it { is_expected.to eq('Check this out https://gitlab-domain.com/uploads/Screenshot1.png') }
    end

    context 'with multiple relative links' do
      let(:message) { 'Check this out ![Screenshot1](/uploads/Screenshot1.png). And this ![Screenshot2](/uploads/Screenshot2.png)' }

      it { is_expected.to eq('Check this out https://gitlab-domain.com/uploads/Screenshot1.png. And this https://gitlab-domain.com/uploads/Screenshot2.png') }
    end
  end
end
