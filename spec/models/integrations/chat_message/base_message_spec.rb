# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ChatMessage::BaseMessage, feature_category: :integrations do
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

    context 'with markdown links' do
      let(:message) { 'Check [this](https://gitlab-domain.com/issue)' }

      it { is_expected.to eq('Check <https://gitlab-domain.com/issue|this>') }
    end

    context 'with HTML links' do
      let(:message) { 'Check <a href="https://evil.example.com">https://gitlab-domain.com/issue</a>' }

      it 'does not convert them into Slack links' do
        is_expected.to eq(message)
      end
    end
  end

  describe '#format_user_text' do
    using RSpec::Parameterized::TableSyntax

    where(:input, :output) do
      'Just text'                                    | 'Just text'
      'See ![shot](/uploads/shot.png)'               | 'See https://gitlab-domain.com/uploads/shot.png'
      '[label](https://evil.example.com)'            | '[label](https://evil.example.com)'
      '<a href="https://evil.example.com">label</a>' | '&lt;a href="https://evil.example.com"&gt;label&lt;/a&gt;'
      '<https://evil.example.com|label>'             | '&lt;https://evil.example.com|label&gt;'
      'Tom & Jerry'                                  | 'Tom &amp; Jerry'
    end

    with_them do
      it 'escapes control characters and leaves link markup unconverted' do
        expect(base_message.send(:format_user_text, input)).to eq(output)
      end
    end
  end

  describe '#strip_markup' do
    using RSpec::Parameterized::TableSyntax

    where(:input, :output) do
      nil                              | nil
      ''                               | ''
      '[label](url)'                   | 'label(url)'
      '<url|label>'                    | 'urllabel'
      '<a href="url">label</a>'        | 'a href="url"label/a'
    end

    with_them do
      it 'returns the expected output' do
        expect(base_message.send(:strip_markup, input)).to eq(output)
      end
    end
  end

  describe '#attachment_color' do
    subject(:attachment_color) { base_message.send(:attachment_color) }

    it 'uses a Mattermost-compatible hex color' do
      expect(attachment_color).to match(/\A#[0-9a-fA-F]{6}\z/)
    end
  end
end
