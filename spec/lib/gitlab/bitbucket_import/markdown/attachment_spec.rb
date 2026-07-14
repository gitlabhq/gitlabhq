# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Markdown::Attachment, feature_category: :importers do
  let(:name) { FFaker::Lorem.word }

  describe '.from_markdown' do
    context "when it's a Bitbucket-hosted image" do
      using RSpec::Parameterized::TableSyntax

      where(:host, :url) do
        'bitbucket.org/repo'         | 'https://bitbucket.org/repo/abc123/images/example.png'
        'bbuseruploads.s3.amazonaws' | 'https://bbuseruploads.s3.amazonaws.com/abc/123/example.png?signature=xyz'
      end

      with_them do
        let(:markdown_node) do
          instance_double(CommonMarker::Node, url: url, to_plaintext: name, type: :image)
        end

        it 'returns an instance with the attachment info' do
          attachment = described_class.from_markdown(markdown_node)

          expect(attachment.name).to eq(name)
          expect(attachment.url).to eq(url)
        end
      end
    end

    context "when it's an image with a non-Bitbucket URL" do
      let(:url) { 'https://example.com/example.png' }
      let(:markdown_node) do
        instance_double(CommonMarker::Node, url: url, to_plaintext: name, type: :image)
      end

      it 'returns nil' do
        expect(described_class.from_markdown(markdown_node)).to be_nil
      end
    end

    context "when it's an image with a nil URL" do
      let(:markdown_node) do
        instance_double(CommonMarker::Node, url: nil, to_plaintext: name, type: :image)
      end

      it 'returns nil' do
        expect(described_class.from_markdown(markdown_node)).to be_nil
      end
    end

    context "when it's an inline HTML img tag on a Bitbucket host" do
      let(:url) { 'https://bitbucket.org/repo/abc123/images/example.png' }
      let(:img_tag) { %(<img width="248" alt="#{name}" src="#{url}">) }
      let(:markdown_node) do
        instance_double(CommonMarker::Node, string_content: img_tag, type: :inline_html)
      end

      it 'returns an instance with the src and alt' do
        attachment = described_class.from_markdown(markdown_node)

        expect(attachment.name).to eq(name)
        expect(attachment.url).to eq(url)
      end
    end

    context "when it's an inline HTML img tag on a non-Bitbucket host" do
      let(:img_tag) { %(<img alt="#{name}" src="https://example.com/example.png">) }
      let(:markdown_node) do
        instance_double(CommonMarker::Node, string_content: img_tag, type: :inline_html)
      end

      it 'returns nil' do
        expect(described_class.from_markdown(markdown_node)).to be_nil
      end
    end

    context "when the node type is not an image or HTML" do
      let(:markdown_node) do
        instance_double(CommonMarker::Node, type: :text)
      end

      it 'returns nil' do
        expect(described_class.from_markdown(markdown_node)).to be_nil
      end
    end
  end
end
