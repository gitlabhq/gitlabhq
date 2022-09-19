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

  describe '.fetch_attachment_urls' do
    let(:image_extension) { described_class::MEDIA_TYPES.sample }
    let(:image_attachment) do
      "![special-image](https://user-images.githubusercontent.com/6833862/"\
        "176685788-e7a93168-7ded-406a-82b5-eb1c56685a93.#{image_extension})"
    end

    let(:doc_extension) { described_class::DOC_TYPES.sample }
    let(:doc_attachment) do
      "[some-doc](https://github.com/nickname/public-test-repo/"\
      "files/9020437/git-cheat-sheet.#{doc_extension})"
    end

    let(:text) do
      <<-TEXT
        Comment with an attachment
        #{image_attachment}
        #{FFaker::Lorem.sentence}
        #{doc_attachment}
      TEXT
    end

    it 'fetches attachment urls' do
      expect(described_class.fetch_attachment_urls(text))
        .to contain_exactly(image_attachment, doc_attachment)
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
