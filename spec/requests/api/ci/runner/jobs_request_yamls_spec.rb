# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, :clean_gitlab_redis_shared_state, feature_category: :continuous_integration do
  include StubGitlabCalls

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, shared_runners_enabled: false, maintainers: user) }
  let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }

  let(:user_agent) { 'gitlab-runner 9.0.0 (9-0-stable; go1.7.4; linux/amd64)' }

  Dir[Rails.root.join("spec/requests/api/ci/runner/yamls/*.yml")].each do |yml_file|
    context "for #{File.basename(yml_file)}" do
      let(:yaml_content) { YAML.load_file(yml_file) }
      let(:gitlab_ci_yml) { yaml_content.fetch("gitlab_ci") }
      let(:request_response) { yaml_content.fetch("request_response") }

      it 'runs a job' do
        stub_ci_pipeline_yaml_file(YAML.dump(gitlab_ci_yml))

        pipeline_response = create_pipeline!
        expect(pipeline_response).to be_success, pipeline_response.message
        expect(pipeline_response.payload).to be_created_successfully
        expect(pipeline_response.payload.builds).to be_one

        build = pipeline_response.payload.builds.first

        process_pipeline!(pipeline_response.payload)
        expect(build.reload).to be_pending

        request_job(runner.token)
        expect(response).to have_gitlab_http_status(:created)
        expect(response.headers['Content-Type']).to eq('application/json')
        expect(json_response).to include('id' => build.id, 'token' => instance_of(String))
        expect(json_response).to include(request_response)
      end
    end
  end

  def create_pipeline!
    params = { ref: 'master',
               before: '00000000',
               after: project.commit.id,
               commits: [{ message: 'some commit' }] }

    Ci::CreatePipelineService.new(project, user, params).execute(:push)
  end

  def process_pipeline!(pipeline)
    PipelineProcessWorker.new.perform(pipeline.id)
  end

  def request_job(token, **params)
    new_params = params.merge(token: token)
    post api('/jobs/request'), params: new_params.to_json,
      headers: { 'User-Agent' => user_agent, 'Content-Type': 'application/json' }
  end
end
