require 'spec_helper'

describe API::V3::Pipelines do
  let(:user)        { create(:user) }
  let(:non_member)  { create(:user) }
  let(:project)     { create(:project, :repository, creator: user) }

  let!(:pipeline) do
    create(:ci_empty_pipeline, project: project, sha: project.commit.id,
                               ref: project.default_branch)
  end

  before { project.add_master(user) }

  shared_examples 'a paginated resources' do
    before do
      # Fires the request
      request
    end

    it 'has pagination headers' do
      expect(response).to include_pagination_headers
    end
  end

  describe 'GET /projects/:id/pipelines ' do
    it_behaves_like 'a paginated resources' do
      let(:request) { get v3_api("/projects/#{project.id}/pipelines", user) }
    end

    context 'authorized user' do
      it 'returns project pipelines' do
        get v3_api("/projects/#{project.id}/pipelines", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['sha']).to match(/\A\h{40}\z/)
        expect(json_response.first['id']).to eq pipeline.id
        expect(json_response.first.keys).to contain_exactly(*%w[id sha ref status before_sha tag yaml_errors user created_at updated_at started_at finished_at committed_at duration coverage])
      end
    end

    context 'unauthorized user' do
      it 'does not return project pipelines' do
        get v3_api("/projects/#{project.id}/pipelines", non_member)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response).not_to be_an Array
      end
    end
  end

  describe 'POST /projects/:id/pipeline ' do
    context 'authorized user' do
      context 'with gitlab-ci.yml' do
        before { stub_ci_pipeline_to_return_yaml_file }

        it 'creates and returns a new pipeline' do
          expect do
            post v3_api("/projects/#{project.id}/pipeline", user), ref: project.default_branch
          end.to change { Ci::Pipeline.count }.by(1)

          expect(response).to have_gitlab_http_status(201)
          expect(json_response).to be_a Hash
          expect(json_response['sha']).to eq project.commit.id
        end

        it 'fails when using an invalid ref' do
          post v3_api("/projects/#{project.id}/pipeline", user), ref: 'invalid_ref'

          expect(response).to have_gitlab_http_status(400)
          expect(json_response['message']['base'].first).to eq 'Reference not found'
          expect(json_response).not_to be_an Array
        end
      end

      context 'without gitlab-ci.yml' do
        it 'fails to create pipeline' do
          post v3_api("/projects/#{project.id}/pipeline", user), ref: project.default_branch

          expect(response).to have_gitlab_http_status(400)
          expect(json_response['message']['base'].first).to eq 'Missing .gitlab-ci.yml file'
          expect(json_response).not_to be_an Array
        end
      end
    end

    context 'unauthorized user' do
      it 'does not create pipeline' do
        post v3_api("/projects/#{project.id}/pipeline", non_member), ref: project.default_branch

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response).not_to be_an Array
      end
    end
  end

  describe 'GET /projects/:id/pipelines/:pipeline_id' do
    context 'authorized user' do
      it 'returns project pipelines' do
        get v3_api("/projects/#{project.id}/pipelines/#{pipeline.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['sha']).to match /\A\h{40}\z/
      end

      it 'returns 404 when it does not exist' do
        get v3_api("/projects/#{project.id}/pipelines/123456", user)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq '404 Not found'
        expect(json_response['id']).to be nil
      end

      context 'with coverage' do
        before do
          create(:ci_build, coverage: 30, pipeline: pipeline)
        end

        it 'exposes the coverage' do
          get v3_api("/projects/#{project.id}/pipelines/#{pipeline.id}", user)

          expect(json_response["coverage"].to_i).to eq(30)
        end
      end
    end

    context 'unauthorized user' do
      it 'should not return a project pipeline' do
        get v3_api("/projects/#{project.id}/pipelines/#{pipeline.id}", non_member)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response['id']).to be nil
      end
    end
  end

  describe 'POST /projects/:id/pipelines/:pipeline_id/retry' do
    context 'authorized user' do
      let!(:pipeline) do
        create(:ci_pipeline, project: project, sha: project.commit.id,
                             ref: project.default_branch)
      end

      let!(:build) { create(:ci_build, :failed, pipeline: pipeline) }

      it 'retries failed builds' do
        expect do
          post v3_api("/projects/#{project.id}/pipelines/#{pipeline.id}/retry", user)
        end.to change { pipeline.builds.count }.from(1).to(2)

        expect(response).to have_gitlab_http_status(201)
        expect(build.reload.retried?).to be true
      end
    end

    context 'unauthorized user' do
      it 'should not return a project pipeline' do
        post v3_api("/projects/#{project.id}/pipelines/#{pipeline.id}/retry", non_member)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response['id']).to be nil
      end
    end
  end

  describe 'POST /projects/:id/pipelines/:pipeline_id/cancel' do
    let!(:pipeline) do
      create(:ci_empty_pipeline, project: project, sha: project.commit.id,
                                 ref: project.default_branch)
    end

    let!(:build) { create(:ci_build, :running, pipeline: pipeline) }

    context 'authorized user' do
      it 'retries failed builds' do
        post v3_api("/projects/#{project.id}/pipelines/#{pipeline.id}/cancel", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['status']).to eq('canceled')
      end
    end

    context 'user without proper access rights' do
      let!(:reporter) { create(:user) }

      before { project.add_reporter(reporter) }

      it 'rejects the action' do
        post v3_api("/projects/#{project.id}/pipelines/#{pipeline.id}/cancel", reporter)

        expect(response).to have_gitlab_http_status(403)
        expect(pipeline.reload.status).to eq('pending')
      end
    end
  end
end
