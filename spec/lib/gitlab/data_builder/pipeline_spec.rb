# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::DataBuilder::Pipeline do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  let(:pipeline) do
    create(:ci_pipeline,
          project: project,
          status: 'success',
          sha: project.commit.sha,
          ref: project.default_branch)
  end

  let!(:build) { create(:ci_build, pipeline: pipeline) }

  describe '.build' do
    let(:data) { described_class.build(pipeline) }
    let(:attributes) { data[:object_attributes] }
    let(:build_data) { data[:builds].first }
    let(:project_data) { data[:project] }

    it 'has correct attributes' do
      expect(attributes).to be_a(Hash)
      expect(attributes[:ref]).to eq(pipeline.ref)
      expect(attributes[:sha]).to eq(pipeline.sha)
      expect(attributes[:tag]).to eq(pipeline.tag)
      expect(attributes[:id]).to eq(pipeline.id)
      expect(attributes[:source]).to eq(pipeline.source)
      expect(attributes[:status]).to eq(pipeline.status)
      expect(attributes[:detailed_status]).to eq('passed')
      expect(build_data).to be_a(Hash)
      expect(build_data[:id]).to eq(build.id)
      expect(build_data[:status]).to eq(build.status)
      expect(build_data[:allow_failure]).to eq(build.allow_failure)
      expect(project_data).to eq(project.hook_attrs(backward: false))
      expect(data[:merge_request]).to be_nil
    end

    context 'pipeline without variables' do
      it 'has empty variables hash' do
        expect(attributes[:variables]).to be_a(Array)
        expect(attributes[:variables]).to be_empty
      end
    end

    context 'pipeline with variables' do
      let(:build) { create(:ci_build, pipeline: pipeline) }
      let(:data) { described_class.build(pipeline) }
      let(:attributes) { data[:object_attributes] }
      let!(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline, key: 'TRIGGER_KEY_1', value: 'TRIGGER_VALUE_1') }

      it { expect(attributes[:variables]).to be_a(Array) }
      it { expect(attributes[:variables]).to contain_exactly({ key: 'TRIGGER_KEY_1', value: 'TRIGGER_VALUE_1' }) }
    end

    context 'when pipeline is a detached merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }
      let(:pipeline) { merge_request.all_pipelines.first }

      it 'returns a source ref' do
        expect(attributes[:ref]).to eq(merge_request.source_branch)
      end

      it 'returns merge request' do
        merge_request_attrs = data[:merge_request]

        expect(merge_request_attrs).to be_a(Hash)
        expect(merge_request_attrs[:id]).to eq(merge_request.id)
        expect(merge_request_attrs[:iid]).to eq(merge_request.iid)
        expect(merge_request_attrs[:title]).to eq(merge_request.title)
        expect(merge_request_attrs[:source_branch]).to eq(merge_request.source_branch)
        expect(merge_request_attrs[:source_project_id]).to eq(merge_request.source_project_id)
        expect(merge_request_attrs[:target_branch]).to eq(merge_request.target_branch)
        expect(merge_request_attrs[:target_project_id]).to eq(merge_request.target_project_id)
        expect(merge_request_attrs[:state]).to eq(merge_request.state)
        expect(merge_request_attrs[:merge_status]).to eq(merge_request.merge_status)
        expect(merge_request_attrs[:url]).to eq("http://localhost/#{merge_request.target_project.full_path}/-/merge_requests/#{merge_request.iid}")
      end
    end
  end
end
