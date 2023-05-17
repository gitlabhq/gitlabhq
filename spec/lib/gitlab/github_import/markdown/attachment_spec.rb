# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Markdown::Attachment, feature_category: :importers do
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

  describe '#part_of_project_blob?' do
    let(:attachment) { described_class.new('test', url) }
    let(:import_source) { 'nickname/public-test-repo' }

    context 'when url is a part of project blob' do
      let(:url) { "https://github.com/#{import_source}/blob/main/example.md" }

      it { expect(attachment.part_of_project_blob?(import_source)).to eq true }
    end

    context 'when url is not a part of project blob' do
      let(:url) { "https://github.com/#{import_source}/files/9020437/git-cheat-sheet.txt" }

      it { expect(attachment.part_of_project_blob?(import_source)).to eq false }
    end
  end

  describe '#doc_belongs_to_project?' do
    let(:attachment) { described_class.new('test', url) }
    let(:import_source) { 'nickname/public-test-repo' }

    context 'when url relates to this project' do
      let(:url) { "https://github.com/#{import_source}/files/9020437/git-cheat-sheet.txt" }

      it { expect(attachment.doc_belongs_to_project?(import_source)).to eq true }
    end

    context 'when url is not related to this project' do
      let(:url) { 'https://github.com/nickname/other-repo/files/9020437/git-cheat-sheet.txt' }

      it { expect(attachment.doc_belongs_to_project?(import_source)).to eq false }
    end

    context 'when url is a part of project blob' do
      let(:url) { "https://github.com/#{import_source}/blob/main/example.md" }

      it { expect(attachment.doc_belongs_to_project?(import_source)).to eq false }
    end
  end

  describe '#media?' do
    let(:attachment) { described_class.new('test', url) }

    context 'when it is a media link' do
      let(:url) { 'https://user-images.githubusercontent.com/6833842/0cf366b61ef2.jpeg' }

      it { expect(attachment.media?).to eq true }
    end

    context 'when it is not a media link' do
      let(:url) { 'https://github.com/nickname/public-test-repo/files/9020437/git-cheat-sheet.txt' }

      it { expect(attachment.media?).to eq false }
    end
  end

  describe '#inspect' do
    it 'returns attachment basic info' do
      attachment = described_class.new(name, url)

      expect(attachment.inspect).to eq "<Gitlab::GithubImport::Markdown::Attachment: { name: #{name}, url: #{url} }>"
    end
  end
end
