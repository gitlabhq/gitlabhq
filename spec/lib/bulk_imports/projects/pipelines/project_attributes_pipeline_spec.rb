# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::ProjectAttributesPipeline do
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
      'build_coverage_regex' => 'build_coverage_regex',
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

  before do
    allow(Dir).to receive(:mktmpdir).with('bulk_imports').and_return(tmpdir)
  end

  after do
    FileUtils.remove_entry(tmpdir) if Dir.exist?(tmpdir)
  end

  describe '#run' do
    before do
      allow(pipeline).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: project_attributes))

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

  describe '#extract' do
    before do
      file_download_service = instance_double("BulkImports::FileDownloadService")
      file_decompression_service = instance_double("BulkImports::FileDecompressionService")

      expect(BulkImports::FileDownloadService)
        .to receive(:new)
        .with(
          configuration: context.configuration,
          relative_url: "/#{entity.pluralized_name}/#{entity.source_full_path}/export_relations/download?relation=self",
          tmpdir: tmpdir,
          filename: 'self.json.gz')
        .and_return(file_download_service)

      expect(BulkImports::FileDecompressionService)
        .to receive(:new)
        .with(tmpdir: tmpdir, filename: 'self.json.gz')
        .and_return(file_decompression_service)

      expect(file_download_service).to receive(:execute)
      expect(file_decompression_service).to receive(:execute)
    end

    it 'downloads, decompresses & decodes json' do
      allow(pipeline).to receive(:json_attributes).and_return("{\"test\":\"test\"}")

      extracted_data = pipeline.extract(context)

      expect(extracted_data.data).to match_array([{ 'test' => 'test' }])
    end

    context 'when json parsing error occurs' do
      it 'raises an error' do
        allow(pipeline).to receive(:json_attributes).and_return("invalid")

        expect { pipeline.extract(context) }.to raise_error(BulkImports::Error)
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

  describe '#json_attributes' do
    it 'reads raw json from file' do
      filepath = File.join(tmpdir, 'self.json')

      FileUtils.touch(filepath)
      expect_file_read(filepath)

      pipeline.json_attributes
    end
  end

  describe '#after_run' do
    it 'removes tmp dir' do
      allow(FileUtils).to receive(:remove_entry).and_call_original
      expect(FileUtils).to receive(:remove_entry).with(tmpdir).and_call_original

      pipeline.after_run(nil)

      expect(Dir.exist?(tmpdir)).to eq(false)
    end

    context 'when dir does not exist' do
      it 'does not attempt to remove tmpdir' do
        FileUtils.remove_entry(tmpdir)

        expect(FileUtils).not_to receive(:remove_entry).with(tmpdir)

        pipeline.after_run(nil)
      end
    end
  end
end
