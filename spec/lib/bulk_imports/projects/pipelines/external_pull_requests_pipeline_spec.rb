# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::ExternalPullRequestsPipeline, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:entity) { create(:bulk_import_entity, :project_entity, project: project, bulk_import: bulk_import) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity, pipeline_name: described_class) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:attributes) { {} }
  let(:external_pr) { project.external_pull_requests.last }
  let(:external_pull_request) do
    {
      'pull_request_iid' => 4,
      'source_branch' => 'feature',
      'target_branch' => 'main',
      'source_repository' => 'repository',
      'target_repository' => 'repository',
      'source_sha' => 'abc',
      'target_sha' => 'xyz',
      'status' => 'open',
      'created_at' => '2019-12-24T14:04:50.053Z',
      'updated_at' => '2019-12-24T14:05:18.138Z'
    }.merge(attributes)
  end

  subject(:pipeline) { described_class.new(context) }

  describe '#run', :clean_gitlab_redis_shared_state do
    before do
      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:remove_tmp_dir)
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [[external_pull_request, 0]]))
      end

      allow(pipeline).to receive(:set_source_objects_counter)

      pipeline.run
    end

    it 'imports external pull request', :aggregate_failures do
      expect(external_pr.pull_request_iid).to eq(external_pull_request['pull_request_iid'])
      expect(external_pr.source_branch).to eq(external_pull_request['source_branch'])
      expect(external_pr.target_branch).to eq(external_pull_request['target_branch'])
      expect(external_pr.status).to eq(external_pull_request['status'])
      expect(external_pr.created_at).to eq(external_pull_request['created_at'])
      expect(external_pr.updated_at).to eq(external_pull_request['updated_at'])
    end

    context 'when status is closed' do
      let(:attributes) { { 'status' => 'closed' } }

      it 'imports closed external pull request' do
        expect(external_pr.status).to eq(attributes['status'])
      end
    end

    context 'when from fork' do
      let(:attributes) { { 'source_repository' => 'source' } }

      it 'does not create external pull request' do
        expect(external_pr).to be_nil
      end
    end
  end
end
