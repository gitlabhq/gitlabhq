# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Markdown::Attachment do
  let(:name) { FFaker::Lorem.word }
  let(:url) { FFaker::Internet.uri('https') }

  describe '.from_markdown' do
    context "when it's a doc attachment" do
      let(:doc_extension) { Gitlab::GithubImport::Markdown::Attachment::DOC_TYPES.sample }
      let(:url) { "https://github.com/nickname/public-test-repo/files/3/git-cheat-sheet.#{doc_extension}" }
      let(:name) { FFaker::Lorem.word }
      let(:markdown_node) do
        instance_double('CommonMarker::Node', url: url, to_plaintext: name, type: :link)
      end

      it 'returns instance with attachment info' do
        attachment = described_class.from_markdown(markdown_node)

        expect(attachment.name).to eq name
        expect(attachment.url).to eq url
      end

      context "when type is not in whitelist" do
        let(:doc_extension) { 'exe' }

        it { expect(described_class.from_markdown(markdown_node)).to eq nil }
      end

      context 'when domain name is unknown' do
        let(:url) do
          "https://bitbucket.com/nickname/public-test-repo/files/3/git-cheat-sheet.#{doc_extension}"
        end

        it { expect(described_class.from_markdown(markdown_node)).to eq nil }
      end

      context 'when URL is blank' do
        let(:url) { nil }

        it { expect(described_class.from_markdown(markdown_node)).to eq nil }
      end
    end

    context "when it's an image attachment" do
      let(:image_extension) { Gitlab::GithubImport::Markdown::Attachment::MEDIA_TYPES.sample }
      let(:url) { "https://user-images.githubusercontent.com/1/uuid-1.#{image_extension}" }
      let(:name) { FFaker::Lorem.word }
      let(:markdown_node) do
        instance_double('CommonMarker::Node', url: url, to_plaintext: name, type: :image)
      end

      it 'returns instance with attachment info' do
        attachment = described_class.from_markdown(markdown_node)

        expect(attachment.name).to eq name
        expect(attachment.url).to eq url
      end

      context "when type is not in whitelist" do
        let(:image_extension) { 'mkv' }

        it { expect(described_class.from_markdown(markdown_node)).to eq nil }
      end

      context 'when domain name is unknown' do
        let(:url) { "https://user-images.github.com/1/uuid-1.#{image_extension}" }

        it { expect(described_class.from_markdown(markdown_node)).to eq nil }
      end

      context 'when URL is blank' do
        let(:url) { nil }

        it { expect(described_class.from_markdown(markdown_node)).to eq nil }
      end
    end

    context "when it's an inline html node" do
      let(:name) { FFaker::Lorem.word }
      let(:image_extension) { Gitlab::GithubImport::Markdown::Attachment::MEDIA_TYPES.sample }
      let(:url) { "https://user-images.githubusercontent.com/1/uuid-1.#{image_extension}" }
      let(:img) { "<img width=\"248\" alt=\"#{name}\" src=\"#{url}\">" }
      let(:markdown_node) do
        instance_double('CommonMarker::Node', string_content: img, type: :inline_html)
      end

      it 'returns instance with attachment info' do
        attachment = described_class.from_markdown(markdown_node)

        expect(attachment.name).to eq name
        expect(attachment.url).to eq url
      end

      context 'when image src is not present' do
        let(:img) { "<img width=\"248\" alt=\"#{name}\">" }

        it { expect(described_class.from_markdown(markdown_node)).to eq nil }
      end
    end
  end

  describe '#inspect' do
    it 'returns attachment basic info' do
      attachment = described_class.new(name, url)

      expect(attachment.inspect).to eq "<Gitlab::GithubImport::Markdown::Attachment: { name: #{name}, url: #{url} }>"
    end
  end
end
