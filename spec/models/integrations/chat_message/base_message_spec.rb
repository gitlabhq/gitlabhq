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

  context 'with HTML formatting' do
    let(:args) { super().merge(html: true) }
    let(:text) { '_Example* `name` [label] <tag> & "quotes"' }
    let(:escaped_text) { '_Example* `name` [label] &lt;tag&gt; &amp; &quot;quotes&quot;' }

    it 'escapes external text without interpreting its markup' do
      expect(base_message.send(:strip_markup, text)).to eq(escaped_text)
    end

    it 'does not escape text again when helpers are composed' do
      escaped = base_message.send(:strip_markup, text)

      expect(base_message.send(:strip_markup, escaped)).to eq(escaped_text)
    end

    it 'preserves nil text' do
      expect(base_message.send(:strip_markup, nil)).to be_nil
    end

    it 'escapes both link labels and URL attributes' do
      url = 'https://gitlab.example.com/project?first=1&second="two"'

      expect(base_message.send(:link, text, url)).to eq(
        '<a href="https://gitlab.example.com/project?first=1&amp;second=&quot;two&quot;">' \
          "#{escaped_text}</a>"
      )
    end

    it 'preserves generated bold text inside a link' do
      label = base_message.send(:bold, text)

      expect(base_message.send(:link, label, 'https://gitlab.example.com/project')).to eq(
        "<a href=\"https://gitlab.example.com/project\"><b>#{escaped_text}</b></a>"
      )
    end

    it 'returns the generated HTML summary without converting links to Slack markup' do
      allow(base_message).to receive(:message).and_return('<b>Example</b>')

      expect(base_message.summary).to eq('<b>Example</b>')
    end
  end

  describe '#bold' do
    it 'preserves the existing Markdown format for other chat integrations' do
      expect(base_message.send(:bold, 'Example <title>')).to eq('*Example title*')
    end
  end

  describe '#attachment_color' do
    subject(:attachment_color) { base_message.send(:attachment_color) }

    it 'uses a Mattermost-compatible hex color' do
      expect(attachment_color).to match(/\A#[0-9a-fA-F]{6}\z/)
    end
  end
end
