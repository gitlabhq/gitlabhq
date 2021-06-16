# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::Pipeline do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  let(:pipeline) do
    create(:ci_pipeline,
          project: project,
          status: 'success',
          sha: project.commit.sha,
          ref: project.default_branch,
          user: user)
  end

  let!(:build) { create(:ci_build, pipeline: pipeline) }

  describe '.build' do
    let(:data) { described_class.build(pipeline) }
    let(:attributes) { data[:object_attributes] }
    let(:build_data) { data[:builds].first }
    let(:runner_data) { build_data[:runner] }
    let(:project_data) { data[:project] }

    it 'has correct attributes', :aggregate_failures do
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
      expect(build_data[:environment]).to be_nil
      expect(runner_data).to eq(nil)
      expect(project_data).to eq(project.hook_attrs(backward: false))
      expect(data[:merge_request]).to be_nil
      expect(data[:user]).to eq({
        id: user.id,
        name: user.name,
        username: user.username,
        avatar_url: user.avatar_url(only_path: false),
        email: user.email
        })
    end

    context 'build with runner' do
      let!(:build) { create(:ci_build, pipeline: pipeline, runner: ci_runner) }
      let!(:tag_names) { %w(tag-1 tag-2) }
      let(:ci_runner) { create(:ci_runner, tag_list: tag_names.map { |n| ActsAsTaggableOn::Tag.create!(name: n)}) }

      it 'has runner attributes', :aggregate_failures do
        expect(runner_data[:id]).to eq(ci_runner.id)
        expect(runner_data[:description]).to eq(ci_runner.description)
        expect(runner_data[:runner_type]).to eq(ci_runner.runner_type)
        expect(runner_data[:active]).to eq(ci_runner.active)
        expect(runner_data[:tags]).to match_array(tag_names)
        expect(runner_data[:is_shared]).to eq(ci_runner.instance_type?)
      end
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
        expect(merge_request_attrs[:merge_status]).to eq(merge_request.public_merge_status)
        expect(merge_request_attrs[:url]).to eq("http://localhost/#{merge_request.target_project.full_path}/-/merge_requests/#{merge_request.iid}")
      end
    end

    context 'when pipeline has retried builds' do
      before do
        create(:ci_build, :retried, pipeline: pipeline)
      end

      it 'does not contain retried builds in payload' do
        expect(data[:builds].count).to eq(1)
        expect(build_data[:id]).to eq(build.id)
      end
    end

    context 'build with environment' do
      let!(:build) { create(:ci_build, :teardown_environment, pipeline: pipeline) }

      it { expect(build_data[:environment][:name]).to eq(build.expanded_environment_name) }
      it { expect(build_data[:environment][:action]).to eq(build.environment_action) }
    end
  end
end
