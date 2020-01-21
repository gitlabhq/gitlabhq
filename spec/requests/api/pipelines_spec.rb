# frozen_string_literal: true

require 'spec_helper'

describe API::Pipelines do
  let(:user)        { create(:user) }
  let(:non_member)  { create(:user) }
  let(:project)     { create(:project, :repository, creator: user) }

  let!(:pipeline) do
    create(:ci_empty_pipeline, project: project, sha: project.commit.id,
                               ref: project.default_branch, user: user)
  end

  before do
    project.add_maintainer(user)
  end

  describe 'GET /projects/:id/pipelines ' do
    it_behaves_like 'pipelines visibility table'

    context 'authorized user' do
      it 'returns project pipelines' do
        get api("/projects/#{project.id}/pipelines", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['sha']).to match /\A\h{40}\z/
        expect(json_response.first['id']).to eq pipeline.id
        expect(json_response.first['web_url']).to be_present
        expect(json_response.first.keys).to contain_exactly(*%w[id sha ref status web_url created_at updated_at])
      end

      context 'when parameter is passed' do
        %w[running pending].each do |target|
          context "when scope is #{target}" do
            before do
              create(:ci_pipeline, project: project, status: target)
            end

            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { scope: target }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              json_response.each { |r| expect(r['status']).to eq(target) }
            end
          end
        end

        context 'when scope is finished' do
          before do
            create(:ci_pipeline, project: project, status: 'success')
            create(:ci_pipeline, project: project, status: 'failed')
            create(:ci_pipeline, project: project, status: 'canceled')
          end

          it 'returns matched pipelines' do
            get api("/projects/#{project.id}/pipelines", user), params: { scope: 'finished' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response).not_to be_empty
            json_response.each { |r| expect(r['status']).to be_in(%w[success failed canceled]) }
          end
        end

        context 'when scope is branches or tags' do
          let!(:pipeline_branch) { create(:ci_pipeline, project: project) }
          let!(:pipeline_tag) { create(:ci_pipeline, project: project, ref: 'v1.0.0', tag: true) }

          context 'when scope is branches' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { scope: 'branches' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              expect(json_response.last['id']).to eq(pipeline_branch.id)
            end
          end

          context 'when scope is tags' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { scope: 'tags' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              expect(json_response.last['id']).to eq(pipeline_tag.id)
            end
          end
        end

        context 'when scope is invalid' do
          it 'returns bad_request' do
            get api("/projects/#{project.id}/pipelines", user), params: { scope: 'invalid-scope' }

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        HasStatus::AVAILABLE_STATUSES.each do |target|
          context "when status is #{target}" do
            before do
              create(:ci_pipeline, project: project, status: target)
              exception_status = HasStatus::AVAILABLE_STATUSES - [target]
              create(:ci_pipeline, project: project, status: exception_status.sample)
            end

            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { status: target }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              json_response.each { |r| expect(r['status']).to eq(target) }
            end
          end
        end

        context 'when status is invalid' do
          it 'returns bad_request' do
            get api("/projects/#{project.id}/pipelines", user), params: { status: 'invalid-status' }

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context 'when ref is specified' do
          before do
            create(:ci_pipeline, project: project)
          end

          context 'when ref exists' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { ref: 'master' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              json_response.each { |r| expect(r['ref']).to eq('master') }
            end
          end

          context 'when ref does not exist' do
            it 'returns empty' do
              get api("/projects/#{project.id}/pipelines", user), params: { ref: 'invalid-ref' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).to be_empty
            end
          end
        end

        context 'when name is specified' do
          let!(:pipeline) { create(:ci_pipeline, project: project, user: user) }

          context 'when name exists' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { name: user.name }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response.first['id']).to eq(pipeline.id)
            end
          end

          context 'when name does not exist' do
            it 'returns empty' do
              get api("/projects/#{project.id}/pipelines", user), params: { name: 'invalid-name' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).to be_empty
            end
          end
        end

        context 'when username is specified' do
          let!(:pipeline) { create(:ci_pipeline, project: project, user: user) }

          context 'when username exists' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { username: user.username }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response.first['id']).to eq(pipeline.id)
            end
          end

          context 'when username does not exist' do
            it 'returns empty' do
              get api("/projects/#{project.id}/pipelines", user), params: { username: 'invalid-username' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).to be_empty
            end
          end
        end

        context 'when yaml_errors is specified' do
          let!(:pipeline1) { create(:ci_pipeline, project: project, yaml_errors: 'Syntax error') }
          let!(:pipeline2) { create(:ci_pipeline, project: project) }

          context 'when yaml_errors is true' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { yaml_errors: true }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response.first['id']).to eq(pipeline1.id)
            end
          end

          context 'when yaml_errors is false' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { yaml_errors: false }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response.first['id']).to eq(pipeline2.id)
            end
          end

          context 'when yaml_errors is invalid' do
            it 'returns bad_request' do
              get api("/projects/#{project.id}/pipelines", user), params: { yaml_errors: 'invalid-yaml_errors' }

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end

        context 'when updated_at filters are specified' do
          let!(:pipeline1) { create(:ci_pipeline, project: project, updated_at: 2.days.ago) }
          let!(:pipeline2) { create(:ci_pipeline, project: project, updated_at: 4.days.ago) }
          let!(:pipeline3) { create(:ci_pipeline, project: project, updated_at: 1.hour.ago) }

          it 'returns pipelines with last update date in specified datetime range' do
            get api("/projects/#{project.id}/pipelines", user), params: { updated_before: 1.day.ago, updated_after: 3.days.ago }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response.first['id']).to eq(pipeline1.id)
          end
        end

        context 'when order_by and sort are specified' do
          context 'when order_by user_id' do
            before do
              create_list(:ci_pipeline, 3, project: project, user: create(:user))
            end

            context 'when sort parameter is valid' do
              it 'sorts as user_id: :desc' do
                get api("/projects/#{project.id}/pipelines", user), params: { order_by: 'user_id', sort: 'desc' }

                expect(response).to have_gitlab_http_status(:ok)
                expect(response).to include_pagination_headers
                expect(json_response).not_to be_empty

                pipeline_ids = Ci::Pipeline.all.order(user_id: :desc).pluck(:id)
                expect(json_response.map { |r| r['id'] }).to eq(pipeline_ids)
              end
            end

            context 'when sort parameter is invalid' do
              it 'returns bad_request' do
                get api("/projects/#{project.id}/pipelines", user), params: { order_by: 'user_id', sort: 'invalid_sort' }

                expect(response).to have_gitlab_http_status(:bad_request)
              end
            end
          end

          context 'when order_by is invalid' do
            it 'returns bad_request' do
              get api("/projects/#{project.id}/pipelines", user), params: { order_by: 'lock_version', sort: 'asc' }

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end
      end
    end

    context 'unauthorized user' do
      it 'does not return project pipelines' do
        get api("/projects/#{project.id}/pipelines", non_member)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response).not_to be_an Array
      end
    end
  end

  describe 'POST /projects/:id/pipeline ' do
    def expect_variables(variables, expected_variables)
      variables.each_with_index do |variable, index|
        expected_variable = expected_variables[index]

        expect(variable.key).to eq(expected_variable['key'])
        expect(variable.value).to eq(expected_variable['value'])
        expect(variable.variable_type).to eq(expected_variable['variable_type'])
      end
    end

    context 'authorized user' do
      context 'with gitlab-ci.yml' do
        before do
          stub_ci_pipeline_to_return_yaml_file
        end

        it 'creates and returns a new pipeline' do
          expect do
            post api("/projects/#{project.id}/pipeline", user), params: { ref: project.default_branch }
          end.to change { project.ci_pipelines.count }.by(1)

          expect(response).to have_gitlab_http_status(201)
          expect(json_response).to be_a Hash
          expect(json_response['sha']).to eq project.commit.id
        end

        context 'variables given' do
          let(:variables) { [{ 'variable_type' => 'file', 'key' => 'UPLOAD_TO_S3', 'value' => 'true' }] }

          it 'creates and returns a new pipeline using the given variables' do
            expect do
              post api("/projects/#{project.id}/pipeline", user), params: { ref: project.default_branch, variables: variables }
            end.to change { project.ci_pipelines.count }.by(1)
            expect_variables(project.ci_pipelines.last.variables, variables)

            expect(response).to have_gitlab_http_status(201)
            expect(json_response).to be_a Hash
            expect(json_response['sha']).to eq project.commit.id
            expect(json_response).not_to have_key('variables')
          end
        end

        describe 'using variables conditions' do
          let(:variables) { [{ 'variable_type' => 'env_var', 'key' => 'STAGING', 'value' => 'true' }] }

          before do
            config = YAML.dump(test: { script: 'test', only: { variables: ['$STAGING'] } })
            stub_ci_pipeline_yaml_file(config)
          end

          it 'creates and returns a new pipeline using the given variables' do
            expect do
              post api("/projects/#{project.id}/pipeline", user), params: { ref: project.default_branch, variables: variables }
            end.to change { project.ci_pipelines.count }.by(1)
            expect_variables(project.ci_pipelines.last.variables, variables)

            expect(response).to have_gitlab_http_status(201)
            expect(json_response).to be_a Hash
            expect(json_response['sha']).to eq project.commit.id
            expect(json_response).not_to have_key('variables')
          end

          context 'condition unmatch' do
            let(:variables) { [{ 'key' => 'STAGING', 'value' => 'false' }] }

            it "doesn't create a job" do
              expect do
                post api("/projects/#{project.id}/pipeline", user), params: { ref: project.default_branch }
              end.not_to change { project.ci_pipelines.count }

              expect(response).to have_gitlab_http_status(400)
            end
          end
        end

        it 'fails when using an invalid ref' do
          post api("/projects/#{project.id}/pipeline", user), params: { ref: 'invalid_ref' }

          expect(response).to have_gitlab_http_status(400)
          expect(json_response['message']['base'].first).to eq 'Reference not found'
          expect(json_response).not_to be_an Array
        end
      end

      context 'without gitlab-ci.yml' do
        context 'without auto devops enabled' do
          before do
            project.update!(auto_devops_attributes: { enabled: false })
          end

          it 'fails to create pipeline' do
            post api("/projects/#{project.id}/pipeline", user), params: { ref: project.default_branch }

            expect(response).to have_gitlab_http_status(400)
            expect(json_response['message']['base'].first).to eq 'Missing CI config file'
            expect(json_response).not_to be_an Array
          end
        end
      end
    end

    context 'unauthorized user' do
      it 'does not create pipeline' do
        post api("/projects/#{project.id}/pipeline", non_member), params: { ref: project.default_branch }

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response).not_to be_an Array
      end
    end
  end

  describe 'GET /projects/:id/pipelines/:pipeline_id' do
    it_behaves_like 'pipelines visibility table' do
      let(:pipelines_api_path) do
        "/projects/#{project.id}/pipelines/#{pipeline.id}"
      end

      let(:api_response) { response_status == 200 ? response : json_response }
      let(:response_200) { match_response_schema('public_api/v4/pipeline/detail') }
    end

    context 'authorized user' do
      it 'exposes known attributes' do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/pipeline/detail')
      end

      it 'returns project pipelines' do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['sha']).to match /\A\h{40}\z/
      end

      it 'returns 404 when it does not exist' do
        get api("/projects/#{project.id}/pipelines/123456", user)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq '404 Not found'
        expect(json_response['id']).to be nil
      end

      context 'with coverage' do
        before do
          create(:ci_build, coverage: 30, pipeline: pipeline)
        end

        it 'exposes the coverage' do
          get api("/projects/#{project.id}/pipelines/#{pipeline.id}", user)

          expect(json_response["coverage"].to_i).to eq(30)
        end
      end
    end

    context 'unauthorized user' do
      it 'does not return a project pipeline' do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}", non_member)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response['id']).to be nil
      end
    end
  end

  describe 'GET /projects/:id/pipelines/latest' do
    context 'authorized user' do
      let(:second_branch) { project.repository.branches[2] }

      let!(:second_pipeline) do
        create(:ci_empty_pipeline, project: project, sha: second_branch.target,
                                   ref: second_branch.name, user: user)
      end

      before do
        create(:ci_empty_pipeline, project: project, sha: project.commit.parent.id,
                                   ref: project.default_branch, user: user)
      end

      context 'default repository branch' do
        it 'gets the latest pipleine' do
          get api("/projects/#{project.id}/pipelines/latest", user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to match_response_schema('public_api/v4/pipeline/detail')
          expect(json_response['ref']).to eq(project.default_branch)
          expect(json_response['sha']).to eq(project.commit.id)
        end
      end

      context 'ref parameter' do
        it 'gets the latest pipleine' do
          get api("/projects/#{project.id}/pipelines/latest", user), params: { ref: second_branch.name }

          expect(response).to have_gitlab_http_status(200)
          expect(response).to match_response_schema('public_api/v4/pipeline/detail')
          expect(json_response['ref']).to eq(second_branch.name)
          expect(json_response['sha']).to eq(second_branch.target)
        end
      end
    end

    context 'unauthorized user' do
      it 'does not return a project pipeline' do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}", non_member)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response['id']).to be nil
      end
    end
  end

  describe 'GET /projects/:id/pipelines/:pipeline_id/variables' do
    subject { get api("/projects/#{project.id}/pipelines/#{pipeline.id}/variables", api_user) }

    let(:api_user) { user }

    context 'user is a mantainer' do
      it 'returns pipeline variables empty' do
        subject

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_empty
      end

      context 'with variables' do
        let!(:variable) { create(:ci_pipeline_variable, pipeline: pipeline, key: 'foo', value: 'bar') }

        it 'returns pipeline variables' do
          subject

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to contain_exactly({ "variable_type" => "env_var", "key" => "foo", "value" => "bar" })
        end
      end
    end

    context 'user is a developer' do
      let(:pipeline_owner_user) { create(:user) }
      let(:pipeline) { create(:ci_empty_pipeline, project: project, user: pipeline_owner_user) }

      before do
        project.add_developer(api_user)
      end

      context 'pipeline created by the developer user' do
        let(:api_user) { pipeline_owner_user }
        let!(:variable) { create(:ci_pipeline_variable, pipeline: pipeline, key: 'foo', value: 'bar') }

        it 'returns pipeline variables' do
          subject

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to contain_exactly({ "variable_type" => "env_var", "key" => "foo", "value" => "bar" })
        end
      end

      context 'pipeline created is not created by the developer user' do
        let(:api_user) { create(:user) }

        it 'does not return pipeline variables' do
          subject

          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    context 'user is not a project member' do
      it 'does not return pipeline variables' do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}/variables", non_member)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq '404 Project Not Found'
      end
    end
  end

  describe 'DELETE /projects/:id/pipelines/:pipeline_id' do
    context 'authorized user' do
      let(:owner) { project.owner }

      it 'destroys the pipeline' do
        delete api("/projects/#{project.id}/pipelines/#{pipeline.id}", owner)

        expect(response).to have_gitlab_http_status(204)
        expect { pipeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'returns 404 when it does not exist' do
        delete api("/projects/#{project.id}/pipelines/123456", owner)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq '404 Not found'
      end

      it 'does not log an audit event' do
        expect { delete api("/projects/#{project.id}/pipelines/#{pipeline.id}", owner) }.not_to change { SecurityEvent.count }
      end

      context 'when the pipeline has jobs' do
        let!(:build) { create(:ci_build, project: project, pipeline: pipeline) }

        it 'destroys associated jobs' do
          delete api("/projects/#{project.id}/pipelines/#{pipeline.id}", owner)

          expect(response).to have_gitlab_http_status(204)
          expect { build.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'unauthorized user' do
      context 'when user is not member' do
        it 'returns a 404' do
          delete api("/projects/#{project.id}/pipelines/#{pipeline.id}", non_member)

          expect(response).to have_gitlab_http_status(404)
          expect(json_response['message']).to eq '404 Project Not Found'
        end
      end

      context 'when user is developer' do
        let(:developer) { create(:user) }

        before do
          project.add_developer(developer)
        end

        it 'returns a 403' do
          delete api("/projects/#{project.id}/pipelines/#{pipeline.id}", developer)

          expect(response).to have_gitlab_http_status(403)
          expect(json_response['message']).to eq '403 Forbidden'
        end
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
          post api("/projects/#{project.id}/pipelines/#{pipeline.id}/retry", user)
        end.to change { pipeline.builds.count }.from(1).to(2)

        expect(response).to have_gitlab_http_status(201)
        expect(build.reload.retried?).to be true
      end
    end

    context 'unauthorized user' do
      it 'does not return a project pipeline' do
        post api("/projects/#{project.id}/pipelines/#{pipeline.id}/retry", non_member)

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
      it 'retries failed builds', :sidekiq_might_not_need_inline do
        post api("/projects/#{project.id}/pipelines/#{pipeline.id}/cancel", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['status']).to eq('canceled')
      end
    end

    context 'user without proper access rights' do
      let!(:reporter) { create(:user) }

      before do
        project.add_reporter(reporter)
      end

      it 'rejects the action' do
        post api("/projects/#{project.id}/pipelines/#{pipeline.id}/cancel", reporter)

        expect(response).to have_gitlab_http_status(403)
        expect(pipeline.reload.status).to eq('pending')
      end
    end
  end
end
