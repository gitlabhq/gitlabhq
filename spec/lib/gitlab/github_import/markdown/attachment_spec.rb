# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Markdown::Attachment, feature_category: :importers do
  let(:name) { FFaker::Lorem.word }
  let(:url) { FFaker::Internet.uri('https') }
  let(:import_source) { 'nickname/public-test-repo' }
  let(:web_endpoint) { 'https://github.com' }

  shared_examples 'rejects base user-attachments URLs' do
    context 'when URL is base user-attachments path with trailing slash' do
      let(:test_url) { "#{web_endpoint}/user-attachments/" }

      it 'returns nil' do
        node = case markdown_node.type
               when :text
                 instance_double(CommonMarker::Node, to_plaintext: test_url, type: :text)
               when :inline_html
                 img_tag = "<img width=\"248\" alt=\"#{name}\" src=\"#{test_url}\">"
                 instance_double(CommonMarker::Node, string_content: img_tag, type: :inline_html)
               else
                 instance_double(CommonMarker::Node, url: test_url, to_plaintext: name, type: markdown_node.type)
               end

        expect(described_class.from_markdown(node, web_endpoint)).to be_nil
      end
    end

    context 'when URL is base user-attachments path without trailing slash' do
      let(:test_url) { "#{web_endpoint}/user-attachments" }

      it 'returns nil' do
        node = case markdown_node.type
               when :text
                 instance_double(CommonMarker::Node, to_plaintext: test_url, type: :text)
               when :inline_html
                 img_tag = "<img width=\"248\" alt=\"#{name}\" src=\"#{test_url}\">"
                 instance_double(CommonMarker::Node, string_content: img_tag, type: :inline_html)
               else
                 instance_double(CommonMarker::Node, url: test_url, to_plaintext: name, type: markdown_node.type)
               end

        expect(described_class.from_markdown(node, web_endpoint)).to be_nil
      end
    end
  end

  describe '.from_markdown' do
    context "when it's a doc attachment" do
      let(:doc_extension) { Gitlab::GithubImport::Markdown::Attachment::DOC_TYPES.sample }
      let(:url) { "https://github.com/nickname/public-test-repo/files/3/git-cheat-sheet.#{doc_extension}" }
      let(:name) { FFaker::Lorem.word }
      let(:markdown_node) do
        instance_double(CommonMarker::Node, url: url, to_plaintext: name, type: :link)
      end

      it 'returns instance with attachment info' do
        attachment = described_class.from_markdown(markdown_node, web_endpoint)

        expect(attachment.name).to eq name
        expect(attachment.url).to eq url
      end

      it_behaves_like 'rejects base user-attachments URLs'

      context 'when URL is invalid user-attachments base path' do
        let(:url) { "#{web_endpoint}/user-attachments/" }

        it 'returns nil' do
          expect(described_class.from_markdown(markdown_node, web_endpoint)).to be_nil
        end
      end

      context "when it's a doc attachment from GHE" do
        let(:web_endpoint) { 'https://gce.kitty.com' }
        let(:url) { "#{web_endpoint}/nickname/public-test-repo/files/3/git-cheat-sheet.pdf" }
        let(:name) { FFaker::Lorem.word }
        let(:markdown_node) do
          instance_double(CommonMarker::Node, url: url, to_plaintext: name, type: :link)
        end

        it 'returns instance with attachment info' do
          attachment = described_class.from_markdown(markdown_node, web_endpoint)

          expect(attachment.name).to eq name
          expect(attachment.url).to eq url
        end
      end

      context "when type is not in whitelist" do
        let(:doc_extension) { 'exe' }

        it { expect(described_class.from_markdown(markdown_node, web_endpoint)).to eq nil }
      end

      context 'when domain name is unknown' do
        let(:url) do
          "https://bitbucket.com/nickname/public-test-repo/files/3/git-cheat-sheet.#{doc_extension}"
        end

        it { expect(described_class.from_markdown(markdown_node, web_endpoint)).to eq nil }
      end

      context 'when URL is blank' do
        let(:url) { nil }

        it { expect(described_class.from_markdown(markdown_node, web_endpoint)).to eq nil }
      end
    end

    context "when it's an image attachment" do
      let(:image_extension) { Gitlab::GithubImport::Markdown::Attachment::MEDIA_TYPES.sample }
      let(:url) { "https://user-images.githubusercontent.com/1/uuid-1.#{image_extension}" }
      let(:name) { FFaker::Lorem.word }
      let(:markdown_node) do
        instance_double(CommonMarker::Node, url: url, to_plaintext: name, type: :image)
      end

      it 'returns instance with attachment info' do
        attachment = described_class.from_markdown(markdown_node, web_endpoint)

        expect(attachment.name).to eq name
        expect(attachment.url).to eq url
      end

      it_behaves_like 'rejects base user-attachments URLs'

      context "when type is not in whitelist" do
        let(:image_extension) { 'mkv' }

        it { expect(described_class.from_markdown(markdown_node, web_endpoint)).to eq nil }
      end

      context 'when domain name is unknown' do
        let(:url) { "https://user-images.github.com/1/uuid-1.#{image_extension}" }

        it { expect(described_class.from_markdown(markdown_node, web_endpoint)).to eq nil }
      end

      context 'with allowed domain as subdomain' do
        let(:url) { "https://user-images.githubusercontent.com.attacker.controlled.domain/1/uuid-1.#{image_extension}" }

        it { expect(described_class.from_markdown(markdown_node, web_endpoint)).to eq nil }
      end

      context 'when URL is blank' do
        let(:url) { nil }

        it { expect(described_class.from_markdown(markdown_node, web_endpoint)).to eq nil }
      end

      context 'when image attachment is in the new format' do
        let(:url) { "https://github.com/#{import_source}/assets/142635249/4b9f9c90-f060-4845-97cf-b24c558bcb11" }

        it 'returns instance with attachment info' do
          attachment = described_class.from_markdown(markdown_node, web_endpoint)

          expect(attachment.name).to eq name
          expect(attachment.url).to eq url
        end
      end

      context 'when the instance is a ghe instance' do
        let(:web_endpoint) { "https://ghe.doggo.com" }
        let(:url) { "#{web_endpoint}/user-attachments/assets/142635249/4b9f9c90-f060-4845-97cf-b24c558bcb11" }

        it 'returns instance with attachment info' do
          attachment = described_class.from_markdown(markdown_node, web_endpoint)

          expect(attachment.name).to eq name
          expect(attachment.url).to eq url
        end
      end
    end

    context "when it's an inline html node" do
      let(:name) { FFaker::Lorem.word }
      let(:image_extension) { Gitlab::GithubImport::Markdown::Attachment::MEDIA_TYPES.sample }
      let(:url) { "https://user-images.githubusercontent.com/1/uuid-1.#{image_extension}" }
      let(:img) { "<img width=\"248\" alt=\"#{name}\" src=\"#{url}\">" }
      let(:markdown_node) do
        instance_double(CommonMarker::Node, string_content: img, type: :inline_html)
      end

      it 'returns instance with attachment info' do
        attachment = described_class.from_markdown(markdown_node, web_endpoint)

        expect(attachment.name).to eq name
        expect(attachment.url).to eq url
      end

      it_behaves_like 'rejects base user-attachments URLs'

      context 'when image src is not present' do
        let(:img) { "<img width=\"248\" alt=\"#{name}\">" }

        it { expect(described_class.from_markdown(markdown_node, web_endpoint)).to eq nil }
      end
    end

    context "when it's a video media attachment" do
      let(:media_attachment_url) { "https://github.com/user-attachments/assets/73433gh" }
      let(:markdown_node) do
        instance_double(CommonMarker::Node, to_plaintext: media_attachment_url, type: :text)
      end

      it 'returns an attachment object with the download url and default name' do
        attachment = described_class.from_markdown(markdown_node, web_endpoint)

        expect(attachment.name).to be("media_attachment")
        expect(attachment.url).to eq media_attachment_url
      end

      it_behaves_like 'rejects base user-attachments URLs'
    end
  end

  describe '#part_of_project_blob?' do
    let(:attachment) { described_class.new('test', url, web_endpoint) }

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
    let(:attachment) { described_class.new('test', url, web_endpoint) }

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
    let(:attachment) { described_class.new('test', url, web_endpoint) }

    context 'when it is a media link' do
      let(:url) { 'https://user-images.githubusercontent.com/6833842/0cf366b61ef2.jpeg' }

      it { expect(attachment.media?(import_source)).to eq true }

      context 'when it is a new media link' do
        let(:url) { "https://github.com/#{import_source}/assets/142635249/4b9f9c90-f060-4845-97cf-b24c558bcb11" }

        it { expect(attachment.media?(import_source)).to eq true }
      end
    end

    context 'when it is not a media link' do
      let(:url) { 'https://github.com/nickname/public-test-repo/files/9020437/git-cheat-sheet.txt' }

      it { expect(attachment.media?(import_source)).to eq false }
    end
  end

  describe '#inspect' do
    it 'returns attachment basic info' do
      attachment = described_class.new(name, url, web_endpoint)

      expect(attachment.inspect).to eq "<Gitlab::GithubImport::Markdown::Attachment: { name: #{name}, url: #{url}, web_endpoint: #{web_endpoint} }>" # rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective -- Needs to be on one line
    end
  end
end
