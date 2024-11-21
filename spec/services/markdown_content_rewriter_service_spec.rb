# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MarkdownContentRewriterService, feature_category: :markdown do
  let_it_be(:user) { create(:user) }
  let_it_be(:source_parent) { create(:project, :public) }
  let_it_be(:target_parent) { create(:project, :public) }

  let(:content) { 'My content' }
  let(:issue) { create(:issue, project: source_parent, description: content) }

  describe '#initialize' do
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
      let_it_be(:source_project) { create(:project) }
      let_it_be(:target_project) { create(:project) }
      let_it_be(:source_group) { create(:group) }
      let_it_be(:target_group) { create(:group) }

      let(:secret1) { '98765432109876543210987654321098' }
      let(:secret2) { '01234567890123456789012345678901' }
      let(:image_uploader) { build(:file_uploader, container: source_parent, secret: secret1) }
      let(:content) { "Text and #{image_uploader.markdown_link}" }

      let(:destination_path) do
        target_uploader = FileUploader.new(target_parent)
        target_uploader.object_store = image_uploader.object_store
        target_uploader.filename = image_uploader.filename
        target_uploader.upload_path
      end

      shared_examples 'rewrite uploads url' do
        it 'rewrites content' do
          # fake secret to predict destination path
          allow(FileUploader).to receive(:generate_secret).and_return(secret2)

          new_content = subject

          expect(Upload.where(model_id: target_model_id, model_type: target_model_type).count).to eq(1)
          expect(new_content[:description]).to include(destination_path)
          expect(new_content[:description]).not_to eq(content)
          expect(new_content[:description].length).to eq(content.length)
          expect(new_content[1]).to eq(nil)
        end
      end

      context 'when source and target are projects' do
        let(:source_parent) { source_project }
        let(:target_parent) { target_project }
        let(:issue) { create(:issue, project: source_project, description: content) }
        let(:target_model_id) { target_project.id }
        let(:target_model_type) { 'Project' }

        it_behaves_like 'rewrite uploads url'
      end

      context 'when source and target are project namespaces' do
        let(:source_parent) { source_project.project_namespace }
        let(:target_parent) { target_project.project_namespace }
        let(:issue) { create(:issue, project: source_project, description: content) }
        let(:target_model_id) { target_project.id }
        let(:target_model_type) { 'Project' }

        it_behaves_like 'rewrite uploads url'
      end

      context 'when source and target are groups' do
        let(:source_parent) { source_group }
        let(:target_parent) { target_group }
        let(:issue) { create(:issue, :group_level, namespace: source_group, description: content) }
        let(:target_model_id) { target_group.id }
        let(:target_model_type) { 'Namespace' }

        it_behaves_like 'rewrite uploads url'
      end

      context 'when source is project and target is project namespace' do
        let(:source_parent) { source_project }
        let(:target_parent) { target_project.project_namespace }
        let(:issue) { create(:issue, project: source_project, description: content) }
        let(:target_model_id) { target_project.id }
        let(:target_model_type) { 'Project' }

        it_behaves_like 'rewrite uploads url'
      end

      context 'when source is project and target is group' do
        let(:source_parent) { source_project }
        let(:target_parent) { target_group }
        let(:issue) { create(:issue, project: source_project, description: content) }
        let(:target_model_id) { target_group.id }
        let(:target_model_type) { 'Namespace' }

        it_behaves_like 'rewrite uploads url'
      end

      context 'when source is project namespace and target is project' do
        let(:source_parent) { source_project.project_namespace }
        let(:target_parent) { target_project }
        let(:issue) { create(:issue, project: source_project, description: content) }
        let(:target_model_id) { target_project.id }
        let(:target_model_type) { 'Project' }

        it_behaves_like 'rewrite uploads url'
      end

      context 'when source is project namespace and target is group' do
        let(:source_parent) { source_project.project_namespace }
        let(:target_parent) { target_group }
        let(:issue) { create(:issue, project: source_project, description: content) }
        let(:target_model_id) { target_group.id }
        let(:target_model_type) { 'Namespace' }

        it_behaves_like 'rewrite uploads url'
      end

      context 'when source is group and target is project' do
        let(:source_parent) { source_group }
        let(:target_parent) { target_project }
        let(:issue) { create(:issue, :group_level, namespace: source_group, description: content) }
        let(:target_model_id) { target_project.id }
        let(:target_model_type) { 'Project' }

        it_behaves_like 'rewrite uploads url'
      end

      context 'when source is group and target is project namespace' do
        let(:source_parent) { source_group }
        let(:target_parent) { target_project.project_namespace }
        let(:issue) { create(:issue, :group_level, namespace: source_group, description: content) }
        let(:target_model_id) { target_project.id }
        let(:target_model_type) { 'Project' }

        it_behaves_like 'rewrite uploads url'
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
      let(:image_uploader) { build(:file_uploader, container: source_parent) }
      let(:content) { "Text and #{image_uploader.markdown_link}" }

      it { is_expected.to eq(false) }
    end

    context 'when content does not have references or uploads' do
      let(:content) { "simples text with ```code```" }

      it { is_expected.to eq(true) }
    end
  end
end
