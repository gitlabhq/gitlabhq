# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PipelineSerializer, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:serializer) do
    described_class.new(current_user: user, project: project)
  end

  let(:disable_failed_builds) { true }

  subject { serializer.represent(resource, { disable_failed_builds: disable_failed_builds }) }

  shared_examples 'represents' do
    describe '#represent' do
      context 'when used without pagination' do
        it 'created a not paginated serializer' do
          expect(serializer).not_to be_paginated
        end

        context 'when a single object is being serialized' do
          let(:resource) { build_stubbed(:ci_empty_pipeline, project: project) }

          it 'serializers the pipeline object' do
            expect(subject[:id]).to eq resource.id
          end
        end

        context 'when multiple objects are being serialized' do
          let(:resource) { Array.new(2) { build_stubbed(:ci_pipeline, project: project) } }

          it 'serializers the array of pipelines' do
            expect(subject).not_to be_empty
            expect(subject.size).to eq(2)
          end
        end
      end

      context 'when used with pagination' do
        let(:request) { double(url: "#{Gitlab.config.gitlab.url}:8080/api/v4/projects?#{query.to_query}", query_parameters: query) }
        let(:response) { spy('response') }
        let(:query) { {} }

        let(:serializer) do
          described_class.new(current_user: user, project: project).with_pagination(request, response)
        end

        it 'created a paginated serializer' do
          expect(serializer).to be_paginated
        end

        context 'when resource is not paginatable' do
          context 'when a single pipeline object is being serialized' do
            let(:resource) { create(:ci_empty_pipeline) }
            let(:query) { { page: 1, per_page: 1 } }

            it 'raises error' do
              expect { subject }.to raise_error(
                Gitlab::Serializer::Pagination::InvalidResourceError)
            end
          end
        end

        context 'when resource is paginatable relation' do
          let(:resource) { Ci::Pipeline.all }
          let(:query) { { page: 1, per_page: 2 } }

          context 'when a single pipeline object is present in relation' do
            before do
              create(:ci_empty_pipeline, project: project)
            end

            it 'serializes pipeline relation' do
              expect(subject.first).to have_key :id
            end
          end

          context 'when a multiple pipeline objects are being serialized' do
            before do
              create_list(:ci_empty_pipeline, 3, project: project)
            end

            it 'serializes appropriate number of objects' do
              expect(subject.count).to be 2
            end

            it 'appends relevant headers' do
              expect(response).to receive(:[]=).with('X-Total', '3')
              expect(response).to receive(:[]=).with('X-Total-Pages', '2')
              expect(response).to receive(:[]=).with('X-Per-Page', '2')

              subject
            end
          end
        end
      end

      context 'when there are pipelines for merge requests' do
        let(:resource) { Ci::Pipeline.all }

        let!(:merge_request_1) do
          create(
            :merge_request,
            :with_detached_merge_request_pipeline,
            target_project: project,
            target_branch: 'master',
            source_project: project,
            source_branch: 'feature'
          )
        end

        let!(:merge_request_2) do
          create(
            :merge_request,
            :with_detached_merge_request_pipeline,
            target_project: project,
            target_branch: 'master',
            source_project: project,
            source_branch: '2-mb-file'
          )
        end

        before_all do
          project.add_developer(user)
        end

        it 'includes merge requests information' do
          expect(subject).to be_all { |entry| entry[:merge_request].present? }
        end

        it 'preloads related merge requests' do
          recorded = ActiveRecord::QueryRecorder.new { subject }
          id_pattern = /#{merge_request_1.id}, #{merge_request_2.id}|#{merge_request_2.id}, #{merge_request_1.id}/
          expected_query = /FROM "merge_requests" WHERE "merge_requests"\."id" IN \(#{id_pattern}\)/

          expect(recorded.log).to include(a_string_matching(expected_query))
        end
      end

      describe 'number of queries when preloaded' do
        subject { serializer.represent(resource, preload: true) }

        let(:resource) { Ci::Pipeline.all }

        # Create pipelines only once and change their attributes if needed.
        before_all do
          # Since RequestStore.active? is true we have to allow the
          # gitaly calls in this block
          # Issue: https://gitlab.com/gitlab-org/gitlab-foss/issues/37772
          Gitlab::GitalyClient.allow_n_plus_1_calls do
            Ci::Pipeline::COMPLETED_STATUSES.each do |status|
              create_pipeline(status)
            end
          end
          Gitlab::GitalyClient.reset_counts
        end

        context 'with the same ref' do
          before do
            # The namespace_bans query is cached causing to a flaky count so we stub the method on the user
            allow(user).to receive(:namespace_bans).and_wrap_original do |original_method, *args, **kwargs, &block|
              original_method.call(*args, **kwargs, &block).reset
            end
          end

          it 'verifies number of queries', :request_store do
            recorded = ActiveRecord::QueryRecorder.new { subject }
            expected_queries = Gitlab.ee? ? 33 : 30

            expect(recorded.count).to be_within(3).of(expected_queries)
            expect(recorded.cached_count).to eq(0)
          end
        end

        context 'with different refs' do
          before do
            Ci::Pipeline.update_all(%(ref = 'feature-' || id))
            Ci::Build.update_all(%(ref = 'feature-' || stage_id))
            # The namespace_bans query is cached causing to a flaky count so we stub the method on the user
            allow(user).to receive(:namespace_bans).and_wrap_original do |original_method, *args, **kwargs, &block|
              original_method.call(*args, **kwargs, &block).reset
            end
          end

          it 'verifies number of queries', :request_store do
            recorded = ActiveRecord::QueryRecorder.new { subject }

            # For each ref there is a permission check if maintainer can update
            # pipeline. With the same ref this check is cached but if refs are
            # different then there is an extra query per ref
            # https://gitlab.com/gitlab-org/gitlab-foss/issues/46368
            expected_queries = Gitlab.ee? ? 36 : 33

            expect(recorded.count).to be_within(3).of(expected_queries)
            expect(recorded.cached_count).to eq(0)
          end
        end

        context 'with triggered pipelines' do
          before do
            pipeline_1 = create(:ci_pipeline, project: project)
            build_1 = create(:ci_build, pipeline: pipeline_1)
            create(:ci_sources_pipeline, source_job: build_1)
          end

          it 'verifies number of queries', :request_store do
            control = ActiveRecord::QueryRecorder.new do
              serializer.represent(Ci::Pipeline.all, preload: true)
            end

            pipeline_2 = create(:ci_pipeline, project: project)
            build_2 = create(:ci_build, pipeline: pipeline_2)
            create(:ci_sources_pipeline, source_job: build_2)

            recorded = ActiveRecord::QueryRecorder.new do
              serializer.represent(Ci::Pipeline.all, preload: true)
            end

            expect(recorded).not_to exceed_query_limit(control)
          end
        end

        context 'with build environments' do
          let_it_be(:production) { create(:environment, :production, project: project) }
          let_it_be(:staging) { create(:environment, :staging, project: project) }

          it 'executes one query to fetch all related environments', :request_store do
            pipeline = create(:ci_pipeline, project: project)
            create(:ci_build, :manual, pipeline: pipeline, environment: production.name)
            create(:ci_build, :manual, pipeline: pipeline, environment: staging.name)
            create(:ci_build, :scheduled, pipeline: pipeline, environment: production.name)
            create(:ci_build, :scheduled, pipeline: pipeline, environment: staging.name)

            expect { subject }.not_to exceed_query_limit(1).for_query(/SELECT "environments".*/)
          end
        end

        context 'with scheduled and manual builds' do
          before do
            create(:ci_build, :scheduled, pipeline: resource.first)
            create(:ci_build, :scheduled, pipeline: resource.second)
            create(:ci_build, :manual, pipeline: resource.first)
            create(:ci_build, :manual, pipeline: resource.second)
          end

          it 'sends at most one metadata query for each type of build', :request_store do
            # 1 for the existing failed builds and 2 for the added scheduled and manual builds
            expect { subject }.not_to exceed_query_limit(1 + 2).for_query(/SELECT "ci_builds_metadata".*/)
          end
        end

        def create_pipeline(status)
          create(
            :ci_empty_pipeline,
            project: project,
            status: status,
            name: 'Build pipeline',
            ref: 'feature'
          ).tap do |pipeline|
            Ci::Build::AVAILABLE_STATUSES.each do |build_status|
              create_build(pipeline, status, build_status)
              # create multiple failed builds to verify no N+1 for failed builds or metadata
              create_list(:ci_build, 3,
                :tags, :triggered, :artifacts,
                pipeline: pipeline, stage: 'test',
                name: 'test', status: 'failed', ref: pipeline.ref
              )
            end
          end
        end

        def create_build(pipeline, stage, status)
          create(
            :ci_build, :tags, :triggered, :artifacts,
            pipeline: pipeline, stage: stage,
            name: stage, status: status, ref: pipeline.ref
          )
        end
      end
    end

    describe '#represent_status' do
      context 'when represents only status' do
        let(:resource) { build_stubbed(:ci_pipeline) }
        let(:status) { resource.detailed_status(instance_double('User')) }

        subject { serializer.represent_status(resource) }

        it 'serializes only status' do
          expect(subject[:text]).to eq(status.text)
          expect(subject[:label]).to eq(status.label)
          expect(subject[:icon]).to eq(status.icon)
          expect(subject[:favicon]).to match_asset_path("/assets/ci_favicons/#{status.favicon}.png")
        end
      end
    end
  end

  context 'when failed builds disabled' do
    it_behaves_like 'represents'
  end

  context 'when failed builds enabled' do
    let(:disable_failed_builds) { false }

    it_behaves_like 'represents'
  end
end
