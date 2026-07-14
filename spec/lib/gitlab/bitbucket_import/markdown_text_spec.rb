# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::MarkdownText, feature_category: :importers do
  describe '.fetch_attachments' do
    let(:bitbucket_image) { 'https://bitbucket.org/repo/abc123/images/example.png' }
    let(:s3_image) { 'https://bbuseruploads.s3.amazonaws.com/abc/123/example.png' }
    let(:external_image) { 'https://example.com/example.png' }

    context 'when the text is nil' do
      it 'returns an empty array' do
        expect(described_class.fetch_attachments(nil)).to eq([])
      end
    end

    context 'when the text is empty' do
      it 'returns an empty array' do
        expect(described_class.fetch_attachments('')).to eq([])
      end
    end

    context 'when the text has no image URLs' do
      it 'returns an empty array' do
        expect(described_class.fetch_attachments('Hello world')).to eq([])
      end
    end

    context 'when the text has Bitbucket and external images' do
      let(:text) do
        <<~MARKDOWN
          Here is a pasted image:

          ![first](#{bitbucket_image})

          And an external one:

          ![second](#{external_image})

          And an S3-hosted one:

          ![third](#{s3_image})
        MARKDOWN
      end

      it 'returns only the Bitbucket attachments, in order' do
        attachments = described_class.fetch_attachments(text)

        expect(attachments.map(&:url)).to eq([bitbucket_image, s3_image])
        expect(attachments.map(&:name)).to eq(%w[first third])
      end
    end
  end
end
