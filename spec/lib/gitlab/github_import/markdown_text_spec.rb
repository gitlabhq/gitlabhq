# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::MarkdownText, feature_category: :importers do
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

    it { expect(described_class.format(text_in, project: project)).to eq text_out }

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

      it { expect(described_class.format(text_in, project: project)).to eq text_out }
    end
  end

  describe '.fetch_attachments' do
    let(:image_extension) { Gitlab::GithubImport::Markdown::Attachment::MEDIA_TYPES.sample }
    let(:image_attachment) do
      "![special-image](https://user-images.githubusercontent.com/1/uuid-1.#{image_extension})"
    end

    let(:img_tag_attachment) do
      "<img width=\"248\" alt=\"tag-image\" src=\"https://user-images.githubusercontent.com/2/"\
      "uuid-2.#{image_extension}\">"
    end

    let(:damaged_img_tag) do
      "<img width=\"248\" alt=\"tag-image\" src=\"https://user-images.githubusercontent.com"
    end

    let(:doc_extension) { Gitlab::GithubImport::Markdown::Attachment::DOC_TYPES.sample }
    let(:doc_attachment) do
      "[some-doc](https://github.com/nickname/public-test-repo/"\
      "files/3/git-cheat-sheet.#{doc_extension})"
    end

    let(:text) do
      <<-TEXT.split("\n").map(&:strip).join("\n")
        Comment with an attachment
        #{image_attachment}
        #{FFaker::Lorem.sentence}
        #{doc_attachment}
        #{damaged_img_tag}
        #{FFaker::Lorem.paragraph}
        #{img_tag_attachment}
      TEXT
    end

    it 'fetches attachments' do
      attachments = described_class.fetch_attachments(text)

      expect(attachments.map(&:name)).to contain_exactly('special-image', 'tag-image', 'some-doc')
      expect(attachments.map(&:url)).to contain_exactly(
        "https://user-images.githubusercontent.com/1/uuid-1.#{image_extension}",
        "https://user-images.githubusercontent.com/2/uuid-2.#{image_extension}",
        "https://github.com/nickname/public-test-repo/files/3/git-cheat-sheet.#{doc_extension}"
      )
    end

    it 'returns an empty array when passed nil' do
      expect(described_class.fetch_attachments(nil)).to be_empty
    end
  end

  describe '#perform' do
    it 'returns the text when the author was found' do
      author = double(:author, login: 'Alice')
      text = described_class.new('Hello', author, true)

      expect(text.perform).to eq('Hello')
    end

    it 'returns the text when the author has no login' do
      author = double(:author, login: nil)
      text = described_class.new('Hello', author, true)

      expect(text.perform).to eq('Hello')
    end

    it 'returns the text with an extra header when the author was not found' do
      author = double(:author, login: 'Alice')
      text = described_class.new('Hello', author)

      expect(text.perform).to eq("*Created by: Alice*\n\nHello")
    end

    it 'cleans invalid chars' do
      author = double(:author, login: 'Alice')
      text = described_class.format("\u0000Hello", author)

      expect(text).to eq("*Created by: Alice*\n\nHello")
    end

    context "when the perform is called" do
      let_it_be(:project) { create(:project) }
      let(:text) { "I said to @sam_allen\0 the code" }
      let(:instance) { described_class.new(text, project:) }

      subject(:format) { instance.perform }

      it 'calls wrap_mentions_in_backticks and convert_ref_links method as a cleaning step' do
        expect(instance).to receive(:wrap_mentions_in_backticks)
        expect(instance).to receive(:convert_ref_links)

        format
      end

      context "when the text is blank?" do
        let(:text) { nil }

        it "skips formatting" do
          expect(instance).not_to receive(:wrap_mentions_in_backticks)
          expect(instance).not_to receive(:convert_ref_links)

          format
        end

        it "returns nil as response" do
          expect(format).to be_nil
        end
      end
    end
  end
end
