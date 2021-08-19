# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::Pipeline do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let_it_be_with_reload(:pipeline) do
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
    let(:build_data) { data[:builds].last }
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
      let_it_be(:tag_names) { %w(tag-1 tag-2) }
      let_it_be(:ci_runner) { create(:ci_runner, tag_list: tag_names.map { |n| ActsAsTaggableOn::Tag.create!(name: n)}) }
      let_it_be(:build) { create(:ci_build, pipeline: pipeline, runner: ci_runner) }

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
      let_it_be(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline, key: 'TRIGGER_KEY_1', value: 'TRIGGER_VALUE_1') }

      it { expect(attributes[:variables]).to be_a(Array) }
      it { expect(attributes[:variables]).to contain_exactly({ key: 'TRIGGER_KEY_1', value: 'TRIGGER_VALUE_1' }) }
    end

    context 'when pipeline is a detached merge request pipeline' do
      let_it_be(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }
      let_it_be(:pipeline) { merge_request.all_pipelines.first }

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
      let_it_be(:retried_build) { create(:ci_build, :retried, pipeline: pipeline) }

      it 'does not contain retried builds in payload' do
        builds = data[:builds]

        expect(builds.pluck(:id)).to contain_exactly(build.id)
      end

      it 'contains retried builds if requested' do
        builds = data.with_retried_builds[:builds]

        expect(builds.pluck(:id)).to contain_exactly(build.id, retried_build.id)
      end
    end

    context 'build with environment' do
      let_it_be(:build) { create(:ci_build, :environment_with_deployment_tier, :with_deployment, pipeline: pipeline) }

      let(:build_environment_data) { build_data[:environment] }

      it 'has environment attributes', :aggregate_failures do
        expect(build_environment_data[:name]).to eq(build.expanded_environment_name)
        expect(build_environment_data[:action]).to eq(build.environment_action)
        expect(build_environment_data[:deployment_tier]).to eq(build.persisted_environment.try(:tier))
      end
    end

    context 'avoids N+1 database queries' do
      it "with multiple builds" do
        # Preparing the pipeline with the minimal builds
        pipeline = create(:ci_pipeline, user: user, project: project)
        create(:ci_build, user: user, project: project, pipeline: pipeline)
        create(:ci_build, :deploy_to_production, :with_deployment, user: user, project: project, pipeline: pipeline)

        # We need `.to_json` as the build hook data is wrapped within `Gitlab::Lazy`
        control_count = ActiveRecord::QueryRecorder.new { described_class.build(pipeline.reload).to_json }.count

        # Adding more builds to the pipeline and serializing the data again
        create_list(:ci_build, 3, user: user, project: project, pipeline: pipeline)
        create(:ci_build, :start_review_app, :with_deployment, user: user, project: project, pipeline: pipeline)
        create(:ci_build, :stop_review_app, :with_deployment, user: user, project: project, pipeline: pipeline)

        expect { described_class.build(pipeline.reload).to_json }.not_to exceed_query_limit(control_count)
      end

      it "with multiple retried builds" do
        # Preparing the pipeline with the minimal builds
        pipeline = create(:ci_pipeline, user: user, project: project)
        create(:ci_build, :retried, user: user, project: project, pipeline: pipeline)
        create(:ci_build, :deploy_to_production, :retried, :with_deployment, user: user, project: project, pipeline: pipeline)

        # We need `.to_json` as the build hook data is wrapped within `Gitlab::Lazy`
        control_count = ActiveRecord::QueryRecorder.new { described_class.build(pipeline.reload).with_retried_builds.to_json }.count

        # Adding more builds to the pipeline and serializing the data again
        create_list(:ci_build, 3, :retried, user: user, project: project, pipeline: pipeline)
        create(:ci_build, :start_review_app, :retried, :with_deployment, user: user, project: project, pipeline: pipeline)
        create(:ci_build, :stop_review_app, :retried, :with_deployment, user: user, project: project, pipeline: pipeline)

        expect { described_class.build(pipeline.reload).with_retried_builds.to_json }.not_to exceed_query_limit(control_count)
      end
    end
  end
end
