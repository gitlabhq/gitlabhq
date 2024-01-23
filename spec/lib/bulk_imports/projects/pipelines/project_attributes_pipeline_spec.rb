# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::ProjectAttributesPipeline, :with_license, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:entity) { create(:bulk_import_entity, :project_entity, project: project, bulk_import: bulk_import) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:tmpdir) { Dir.mktmpdir }
  let(:extra) { {} }
  let(:project_attributes) do
    {
      'description' => 'description',
      'visibility_level' => 0,
      'archived' => false,
      'merge_requests_template' => 'test',
      'merge_requests_rebase_enabled' => true,
      'approvals_before_merge' => 0,
      'reset_approvals_on_push' => true,
      'merge_requests_ff_only_enabled' => true,
      'issues_template' => 'test',
      'shared_runners_enabled' => true,
      'build_allow_git_fetch' => true,
      'build_timeout' => 3600,
      'pending_delete' => false,
      'public_builds' => true,
      'last_repository_check_failed' => nil,
      'only_allow_merge_if_pipeline_succeeds' => true,
      'has_external_issue_tracker' => false,
      'request_access_enabled' => true,
      'has_external_wiki' => false,
      'ci_config_path' => nil,
      'only_allow_merge_if_all_discussions_are_resolved' => true,
      'printing_merge_request_link_enabled' => true,
      'auto_cancel_pending_pipelines' => 'enabled',
      'service_desk_enabled' => false,
      'delete_error' => nil,
      'disable_overriding_approvers_per_merge_request' => true,
      'resolve_outdated_diff_discussions' => true,
      'jobs_cache_index' => nil,
      'external_authorization_classification_label' => nil,
      'pages_https_only' => false,
      'merge_requests_author_approval' => false,
      'merge_requests_disable_committers_approval' => true,
      'require_password_to_approve' => true,
      'remove_source_branch_after_merge' => true,
      'autoclose_referenced_issues' => true,
      'suggestion_commit_message' => 'Test!'
    }.merge(extra)
  end

  subject(:pipeline) { described_class.new(context) }

  describe '#run' do
    before do
      allow_next_instance_of(BulkImports::Common::Extractors::JsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(
          BulkImports::Pipeline::ExtractedData.new(data: project_attributes)
        )
      end

      allow(pipeline).to receive(:set_source_objects_counter)

      pipeline.run
    end

    it 'imports project attributes', :aggregate_failures do
      project_attributes.each_pair do |key, value|
        expect(project.public_send(key)).to eq(value)
      end
    end

    context 'when project is archived' do
      let(:extra) { { 'archived' => true } }

      it 'sets project as archived' do
        expect(project.archived).to eq(true)
      end
    end
  end

  describe '#transform' do
    it 'removes prohibited attributes from hash' do
      input = { 'description' => 'description', 'issues' => [], 'milestones' => [], 'id' => 5 }

      expect(Gitlab::ImportExport::AttributeCleaner).to receive(:clean).and_call_original

      expect(pipeline.transform(context, input)).to eq({ 'description' => 'description' })
    end
  end

  describe '#load' do
    it 'assigns attributes, drops visibility and reconciles shared runner setting' do
      expect(project).to receive(:assign_attributes).with(project_attributes)
      expect(project).to receive(:reconcile_shared_runners_setting!)
      expect(project).to receive(:drop_visibility_level!)
      expect(project).to receive(:save!)

      pipeline.load(context, project_attributes)
    end
  end

  describe '#after_run' do
    it 'calls extractor#remove_tmpdir' do
      expect_next_instance_of(BulkImports::Common::Extractors::JsonExtractor) do |extractor|
        expect(extractor).to receive(:remove_tmpdir)
      end

      pipeline.after_run(nil)
    end
  end

  describe '.relation' do
    it { expect(described_class.relation).to eq('self') }
  end
end
