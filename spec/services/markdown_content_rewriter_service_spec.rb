# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MarkdownContentRewriterService do
  let_it_be(:user) { create(:user) }
  let_it_be(:source_parent) { create(:project, :public) }
  let_it_be(:target_parent) { create(:project, :public) }

  let(:content) { 'My content' }

  describe '#initialize' do
    it 'raises an error if source_parent is not a Project' do
      expect do
        described_class.new(user, content, create(:group), target_parent)
      end.to raise_error(ArgumentError, 'The rewriter classes require that `source_parent` is a `Project`')
    end
  end

  describe '#execute' do
    subject { described_class.new(user, content, source_parent, target_parent).execute }

    it 'calls the rewriter classes successfully', :aggregate_failures do
      [Gitlab::Gfm::ReferenceRewriter, Gitlab::Gfm::UploadsRewriter].each do |rewriter_class|
        service = double

        expect(service).to receive(:rewrite).with(target_parent)
        expect(rewriter_class).to receive(:new).and_return(service)
      end

      subject
    end

    # Perform simple integration-style tests for each rewriter class.
    # to prove they run correctly.
    context 'when content contains a reference' do
      let_it_be(:issue) { create(:issue, project: source_parent) }

      let(:content) { "See ##{issue.iid}" }

      it 'rewrites content' do
        expect(subject).to eq("See #{source_parent.full_path}##{issue.iid}")
      end
    end

    context 'when content contains an upload' do
      let(:image_uploader) { build(:file_uploader, project: source_parent) }
      let(:content) { "Text and #{image_uploader.markdown_link}" }

      it 'rewrites content' do
        new_content = subject

        expect(new_content).not_to eq(content)
        expect(new_content.length).to eq(content.length)
      end
    end
  end
end
