# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::CiPipelinesPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      :project_entity,
      project: project,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_slug: 'My-Destination-Project',
      destination_namespace: group.full_path
    )
  end

  let(:ci_pipeline_attributes) { {} }
  let(:ci_pipeline) do
    {
      sha: "fakesha",
      ref: "fakeref",
      project: project,
      source: "web"
    }.merge(ci_pipeline_attributes)
  end

  let(:ci_pipeline2) do
    {
      sha: "fakesha2",
      ref: "fakeref2",
      project: project,
      source: "web"
    }.merge(ci_pipeline_attributes)
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject(:pipeline) { described_class.new(context) }

  before do
    allow(pipeline).to receive(:set_source_objects_counter)
  end

  describe '#run', :clean_gitlab_redis_shared_state do
    before do
      group.add_owner(user)

      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(
          BulkImports::Pipeline::ExtractedData.new(data: [ci_pipeline, ci_pipeline2])
        )
      end

      allow_next_instance_of(Repository) do |repository|
        allow(repository).to receive(:fetch_source_branch!)
      end

      pipeline.run
    end

    it 'imports Ci::Pipeline into destination project' do
      expect(project.all_pipelines.count).to eq(2)
      expect(project.ci_pipelines.first.sha).to eq('fakesha')
      expect(project.ci_pipelines.second.sha).to eq('fakesha2')
    end

    context 'notes' do
      let(:ci_pipeline_attributes) do
        {
          'notes' => [
            {
              'note' => 'test note',
              'author_id' => 22,
              'noteable_type' => 'Commit',
              'sha' => '',
              'author' => {
                'name' => 'User 22'
              },
              'commit_id' => 'fakesha',
              'updated_at' => '2016-06-14T15:02:47.770Z',
              'events' => [
                {
                  'action' => 'created',
                  'author_id' => 22
                }
              ]
            }
          ]
        }
      end

      it 'imports pipeline with notes' do
        note = project.all_pipelines.first.notes.first
        expect(note.note).to include('test note')
        expect(note.events.first.action).to eq('created')
      end
    end

    context 'stages' do
      let(:ci_pipeline_attributes) do
        {
          'stages' => [
            {
              'name' => 'test stage',
              'statuses' => [
                {
                  'name' => 'first status',
                  'status' => 'created'
                }
              ],
              'builds' => [
                {
                  'name' => 'second status',
                  'status' => 'created',
                  'ref' => 'abcd'
                }
              ]
            }
          ]
        }
      end

      it 'imports pipeline with notes' do
        stage = project.all_pipelines.first.stages.first
        expect(stage.name).to eq('test stage')
        expect(stage.statuses.first.name).to eq('first status')
        expect(stage.builds.first.name).to eq('second status')
      end
    end

    context 'external pull request' do
      let(:ci_pipeline_attributes) do
        {
          'source' => 'external_pull_request_event',
          'external_pull_request' => {
            'source_branch' => 'test source branch',
            'target_branch' => 'master',
            'source_sha' => 'testsha',
            'target_sha' => 'targetsha',
            'source_repository' => 'test repository',
            'target_repository' => 'test repository',
            'status' => 1,
            'pull_request_iid' => 1
          }
        }
      end

      it 'imports pipeline with external pull request' do
        pull_request = project.all_pipelines.first.external_pull_request
        expect(pull_request.source_branch).to eq('test source branch')
        expect(pull_request.status).to eq('open')
      end
    end

    context 'merge request' do
      let(:ci_pipeline_attributes) do
        {
          'source' => 'merge_request_event',
          'merge_request' => {
            'description' => 'test merge request',
            'title' => 'test MR',
            'source_branch' => 'test source branch',
            'target_branch' => 'master',
            'source_sha' => 'testsha',
            'target_sha' => 'targetsha',
            'source_repository' => 'test repository',
            'target_repository' => 'test repository',
            'target_project_id' => project.id,
            'source_project_id' => project.id,
            'author_id' => user.id
          }
        }
      end

      it 'imports pipeline with external pull request' do
        merge_request = project.all_pipelines.first.merge_request
        expect(merge_request.source_branch).to eq('test source branch')
        expect(merge_request.description).to eq('test merge request')
      end
    end
  end
end
