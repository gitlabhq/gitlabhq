# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::CiPipelinesPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:bulk_import) { create(:bulk_import, :with_configuration, user: user) }
  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      :project_entity,
      project_id: project.id,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_slug: 'My-Destination-Project',
      destination_namespace: group.full_path
    )
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:ci_pipeline_attributes) { {} }
  let(:ci_pipeline) do
    {
      sha: "fakesha",
      ref: "fakeref",
      project_id: project.id,
      source: "web"
    }.merge(ci_pipeline_attributes)
  end

  let(:ci_pipeline2) do
    {
      sha: "fakesha2",
      ref: "fakeref2",
      project_id: project.id,
      source: "web"
    }.merge(ci_pipeline_attributes)
  end

  let(:importer_user_mapping_enabled) { false }
  let(:extract_data) { [ci_pipeline, ci_pipeline2] }

  subject(:pipeline) { described_class.new(context) }

  before do
    allow(pipeline).to receive(:set_source_objects_counter)
  end

  describe '#run', :clean_gitlab_redis_shared_state do
    before do
      group.add_owner(user)

      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(
          BulkImports::Pipeline::ExtractedData.new(data: extract_data)
        )
      end

      allow_next_instance_of(Repository) do |repository|
        allow(repository).to receive(:fetch_source_branch!)
      end

      allow(context).to receive(:importer_user_mapping_enabled?).and_return(importer_user_mapping_enabled)
      allow(Import::PlaceholderReferences::PushService).to receive(:from_record).and_call_original

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

    context 'when importer_user_mapping is enabled' do
      let_it_be(:source_user) do
        create(:import_source_user,
          import_type: ::Import::SOURCE_DIRECT_TRANSFER,
          namespace: group,
          source_user_identifier: 101,
          source_hostname: bulk_import.configuration.url
        )
      end

      let(:importer_user_mapping_enabled) { true }
      let(:extract_data) { [ci_pipeline] }
      let(:ci_pipeline) do
        {
          sha: "fakesha",
          ref: "fakeref",
          project_id: 7,
          source: "web",
          user_id: 101,
          stages: [
            {
              name: 'Stage 1',
              builds: [
                {
                  status: "success",
                  name: "build",
                  stage_idx: 1,
                  ref: "master",
                  type: "Ci::Build",
                  scheduling_type: "stage",
                  commit_id: 2,
                  project_id: 7,
                  user_id: 101
                }
              ],
              generic_commit_statuses: [
                {
                  status: "success",
                  name: "generic",
                  stage_idx: 1,
                  ref: "master",
                  type: "GenericCommitStatus",
                  scheduling_type: "stage",
                  commit_id: 1,
                  project_id: 7,
                  user_id: 101
                }
              ],
              bridges: [
                {
                  status: "success",
                  name: "bridge",
                  stage_idx: 1,
                  ref: "master",
                  type: "Ci::Bridge",
                  scheduling_type: "stage",
                  commit_id: 1,
                  project_id: 7,
                  user_id: 101
                }
              ]
            }
          ]
        }.merge(ci_pipeline_attributes)
        .deep_stringify_keys
      end

      it 'imports ci pipelines and map user references to placeholder users', :aggregate_failures do
        ci_pipeline = project.all_pipelines.first
        stage = project.all_pipelines.first.stages.first
        build = stage.builds.first
        generic_commit_status = stage.generic_commit_statuses.first
        bridge = stage.bridges.first

        expect(ci_pipeline.user).to be_placeholder
        expect(build.user).to be_placeholder
        expect(generic_commit_status.user).to be_placeholder
        expect(bridge.user).to be_placeholder

        source_user = Import::SourceUser.find_by(source_user_identifier: 101)
        expect(source_user.placeholder_user).to be_placeholder

        expect(Import::PlaceholderReferences::PushService).to have_received(:from_record).exactly(4).times
      end

      context 'when merge request is present in the extract data' do
        let(:ci_pipeline_attributes) do
          {
            source: 'merge_request_event',
            merge_request: {
              iid: 1,
              title: 'MR',
              source_branch: 'source_branch',
              target_branch: 'master',
              source_sha: 'testsha',
              target_sha: 'targetsha',
              source_repository: 'test repository',
              target_repository: 'test repository',
              target_project_id: 7,
              source_project_id: 7,
              author_id: 101
            }
          }
        end

        it 'pushes placeholder references for the merge request' do
          expect(Import::PlaceholderReferences::PushService).to have_received(:from_record).with(a_hash_including(
            record: an_instance_of(MergeRequest)
          ))
        end

        context 'when merge request already exists in the database' do
          let_it_be(:merge_request) { create(:merge_request, source_project: project, iid: 1) }

          it 'does not push placeholder references for the merge request' do
            expect(Import::PlaceholderReferences::PushService).not_to have_received(:from_record).with(a_hash_including(
              record: an_instance_of(MergeRequest)
            ))
          end
        end
      end
    end
  end
end
