# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::MarkdownText do
  describe '.format' do
    it 'formats the text' do
      author = double(:author, login: 'Alice')
      text = described_class.format('Hello', author)

      expect(text).to eq("*Created by: Alice*\n\nHello")
    end
  end

  describe '.convert_ref_links' do
    let_it_be(:project) { create(:project) }

    let(:paragraph) { FFaker::Lorem.paragraph }
    let(:sentence) { FFaker::Lorem.sentence }
    let(:issue_id) { rand(100) }
    let(:pull_id) { rand(100) }

    let(:text_in) do
      <<-TEXT
        #{paragraph}
        https://github.com/#{project.import_source}/issues/#{issue_id}
        #{sentence}
        https://github.com/#{project.import_source}/pull/#{pull_id}
      TEXT
    end

    let(:text_out) do
      <<-TEXT
        #{paragraph}
        http://localhost/#{project.full_path}/-/issues/#{issue_id}
        #{sentence}
        http://localhost/#{project.full_path}/-/merge_requests/#{pull_id}
      TEXT
    end

    it { expect(described_class.convert_ref_links(text_in, project)).to eq text_out }

    context 'when Github EE with custom domain name' do
      let(:github_domain) { 'https://custom.github.com/' }
      let(:text_in) do
        <<-TEXT
        #{paragraph}
        #{github_domain}#{project.import_source}/issues/#{issue_id}
        #{sentence}
        #{github_domain}#{project.import_source}/pull/#{pull_id}
        TEXT
      end

      before do
        allow(Gitlab::Auth::OAuth::Provider)
          .to receive(:config_for).with('github').and_return({ 'url' => github_domain })
      end

      it { expect(described_class.convert_ref_links(text_in, project)).to eq text_out }
    end
  end

  describe '#to_s' do
    it 'returns the text when the author was found' do
      author = double(:author, login: 'Alice')
      text = described_class.new('Hello', author, true)

      expect(text.to_s).to eq('Hello')
    end

    it 'returns the text when the author has no login' do
      author = double(:author, login: nil)
      text = described_class.new('Hello', author, true)

      expect(text.to_s).to eq('Hello')
    end

    it 'returns empty text when it receives nil' do
      author = double(:author, login: nil)
      text = described_class.new(nil, author, true)

      expect(text.to_s).to eq('')
    end

    it 'returns the text with an extra header when the author was not found' do
      author = double(:author, login: 'Alice')
      text = described_class.new('Hello', author)

      expect(text.to_s).to eq("*Created by: Alice*\n\nHello")
    end

    it 'cleans invalid chars' do
      author = double(:author, login: 'Alice')
      text = described_class.format("\u0000Hello", author)

      expect(text.to_s).to eq("*Created by: Alice*\n\nHello")
    end
  end
end
