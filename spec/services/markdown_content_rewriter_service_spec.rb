# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MarkdownContentRewriterService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:source_parent) { create(:project, :public) }
  let_it_be(:target_parent) { create(:project, :public) }

  let(:content) { 'My content' }
  let(:issue) { create(:issue, project: source_parent, description: content) }

  describe '#initialize' do
    it 'raises an error if source_parent is not a Project' do
      expect do
        described_class.new(user, issue, :description, create(:group), target_parent)
      end.to raise_error(ArgumentError, 'The rewriter classes require that `source_parent` is a `Project`')
    end

    it 'raises an error if field does not have cached markdown' do
      expect do
        described_class.new(user, issue, :author, source_parent, target_parent)
      end.to raise_error(ArgumentError, 'The `field` attribute does not contain cached markdown')
    end
  end

  describe '#execute' do
    subject { described_class.new(user, issue, :description, source_parent, target_parent).execute }

    context 'when content does not need a rewrite' do
      it 'returns original content and cached html' do
        expect(subject).to eq({
          'description' => issue.description,
          'description_html' => issue.description_html,
          'skip_markdown_cache_validation' => true
        })
      end
    end

    context 'when content needs a rewrite' do
      it 'calls the rewriter classes successfully', :aggregate_failures do
        described_class::REWRITERS.each do |rewriter_class|
          service = double

          allow(service).to receive(:needs_rewrite?).and_return(true)

          expect(service).to receive(:rewrite).with(target_parent)
          expect(rewriter_class).to receive(:new).and_return(service)
        end

        subject
      end
    end

    # Perform simple integration-style tests for each rewriter class.
    # to prove they run correctly.
    context 'when content has references' do
      let_it_be(:issue_to_reference) { create(:issue, project: source_parent) }

      let(:content) { "See ##{issue_to_reference.iid}" }

      it 'rewrites content' do
        expect(subject).to eq({
          'description' => "See #{source_parent.full_path}##{issue_to_reference.iid}",
          'description_html' => nil,
          'skip_markdown_cache_validation' => false
        })
      end
    end

    context 'when content contains an upload' do
      let(:image_uploader) { build(:file_uploader, project: source_parent) }
      let(:content) { "Text and #{image_uploader.markdown_link}" }

      it 'rewrites content' do
        new_content = subject

        expect(new_content[:description]).not_to eq(content)
        expect(new_content[:description].length).to eq(content.length)
        expect(new_content[1]).to eq(nil)
      end
    end
  end

  describe '#safe_to_copy_markdown?' do
    subject do
      rewriter = described_class.new(user, issue, :description, source_parent, target_parent)
      rewriter.safe_to_copy_markdown?
    end

    context 'when content has references' do
      let(:milestone) { create(:milestone, project: source_parent) }
      let(:content) { "Description that references #{milestone.to_reference}" }

      it { is_expected.to eq(false) }
    end

    context 'when content has uploaded file references' do
      let(:image_uploader) { build(:file_uploader, project: source_parent) }
      let(:content) { "Text and #{image_uploader.markdown_link}" }

      it { is_expected.to eq(false) }
    end

    context 'when content does not have references or uploads' do
      let(:content) { "simples text with ```code```" }

      it { is_expected.to eq(true) }
    end
  end
end
