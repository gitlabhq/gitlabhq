# frozen_string_literal: true

require 'spec_helper'

describe PipelineSerializer do
  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }

  let(:serializer) do
    described_class.new(current_user: user, project: project)
  end

  before do
    stub_feature_flags(ci_pipeline_persisted_stages: true)
  end

  subject { serializer.represent(resource) }

  describe '#represent' do
    context 'when used without pagination' do
      it 'created a not paginated serializer' do
        expect(serializer).not_to be_paginated
      end

      context 'when a single object is being serialized' do
        let(:resource) { create(:ci_empty_pipeline, project: project) }

        it 'serializers the pipeline object' do
          expect(subject[:id]).to eq resource.id
        end
      end

      context 'when multiple objects are being serialized' do
        let(:resource) { create_list(:ci_pipeline, 2, project: project) }

        it 'serializers the array of pipelines' do
          expect(subject).not_to be_empty
        end
      end
    end

    context 'when used with pagination' do
      let(:request) { double(url: "#{Gitlab.config.gitlab.url}:8080/api/v4/projects?#{query.to_query}", query_parameters: query) }
      let(:response) { spy('response') }
      let(:query) { {} }

      let(:serializer) do
        described_class.new(current_user: user)
          .with_pagination(request, response)
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
            create(:ci_empty_pipeline)
          end

          it 'serializes pipeline relation' do
            expect(subject.first).to have_key :id
          end
        end

        context 'when a multiple pipeline objects are being serialized' do
          before do
            create_list(:ci_empty_pipeline, 3)
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
        create(:merge_request,
          :with_detached_merge_request_pipeline,
          target_project: project,
          target_branch: 'master',
          source_project: project,
          source_branch: 'feature')
      end

      let!(:merge_request_2) do
        create(:merge_request,
          :with_detached_merge_request_pipeline,
          target_project: project,
          target_branch: 'master',
          source_project: project,
          source_branch: '2-mb-file')
      end

      before do
        project.add_developer(user)
      end

      it 'includes merge requests information' do
        expect(subject.all? { |entry| entry[:merge_request].present? }).to be_truthy
      end

      it 'preloads related merge requests' do
        recorded = ActiveRecord::QueryRecorder.new { subject }
        expected_query = "SELECT \"merge_requests\".* FROM \"merge_requests\" " \
        "WHERE \"merge_requests\".\"id\" IN (#{merge_request_1.id}, #{merge_request_2.id})"

        expect(recorded.log).to include(a_string_starting_with(expected_query))
      end
    end

    describe 'number of queries when preloaded' do
      subject { serializer.represent(resource, preload: true) }

      let(:resource) { Ci::Pipeline.all }

      before do
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
        let(:ref) { 'feature' }

        it 'verifies number of queries', :request_store do
          recorded = ActiveRecord::QueryRecorder.new { subject }
          expected_queries = Gitlab.ee? ? 42 : 39

          expect(recorded.count).to be_within(2).of(expected_queries)
          expect(recorded.cached_count).to eq(0)
        end
      end

      context 'with different refs' do
        def ref
          @sequence ||= 0
          @sequence += 1
          "feature-#{@sequence}"
        end

        it 'verifies number of queries', :request_store do
          recorded = ActiveRecord::QueryRecorder.new { subject }

          # For each ref there is a permission check if maintainer can update
          # pipeline. With the same ref this check is cached but if refs are
          # different then there is an extra query per ref
          # https://gitlab.com/gitlab-org/gitlab-foss/issues/46368
          expected_queries = Gitlab.ee? ? 45 : 42

          expect(recorded.count).to be_within(2).of(expected_queries)
          expect(recorded.cached_count).to eq(0)
        end
      end

      def create_pipeline(status)
        create(:ci_empty_pipeline,
               project: project,
               status: status,
               ref: ref).tap do |pipeline|
          Ci::Build::AVAILABLE_STATUSES.each do |status|
            create_build(pipeline, status, status)
          end
        end
      end

      def create_build(pipeline, stage, status)
        create(:ci_build, :tags, :triggered, :artifacts,
          pipeline: pipeline, stage: stage,
          name: stage, status: status, ref: pipeline.ref)
      end
    end
  end

  describe '#represent_status' do
    context 'when represents only status' do
      let(:resource) { create(:ci_pipeline) }
      let(:status) { resource.detailed_status(double('user')) }

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
