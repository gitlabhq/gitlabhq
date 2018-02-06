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
    project.add_master(user)
  end

  describe 'GET /projects/:id/pipelines ' do
    context 'authorized user' do
      it 'returns project pipelines' do
        get api("/projects/#{project.id}/pipelines", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['sha']).to match /\A\h{40}\z/
        expect(json_response.first['id']).to eq pipeline.id
        expect(json_response.first.keys).to contain_exactly(*%w[id sha ref status])
      end

      context 'when parameter is passed' do
        %w[running pending].each do |target|
          context "when scope is #{target}" do
            before do
              create(:ci_pipeline, project: project, status: target)
            end

            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), scope: target

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
            get api("/projects/#{project.id}/pipelines", user), scope: 'finished'

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
              get api("/projects/#{project.id}/pipelines", user), scope: 'branches'

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              expect(json_response.last['id']).to eq(pipeline_branch.id)
            end
          end

          context 'when scope is tags' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), scope: 'tags'

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              expect(json_response.last['id']).to eq(pipeline_tag.id)
            end
          end
        end

        context 'when scope is invalid' do
          it 'returns bad_request' do
            get api("/projects/#{project.id}/pipelines", user), scope: 'invalid-scope'

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
              get api("/projects/#{project.id}/pipelines", user), status: target

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              json_response.each { |r| expect(r['status']).to eq(target) }
            end
          end
        end

        context 'when status is invalid' do
          it 'returns bad_request' do
            get api("/projects/#{project.id}/pipelines", user), status: 'invalid-status'

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context 'when ref is specified' do
          before do
            create(:ci_pipeline, project: project)
          end

          context 'when ref exists' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), ref: 'master'

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              json_response.each { |r| expect(r['ref']).to eq('master') }
            end
          end

          context 'when ref does not exist' do
            it 'returns empty' do
              get api("/projects/#{project.id}/pipelines", user), ref: 'invalid-ref'

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
              get api("/projects/#{project.id}/pipelines", user), name: user.name

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response.first['id']).to eq(pipeline.id)
            end
          end

          context 'when name does not exist' do
            it 'returns empty' do
              get api("/projects/#{project.id}/pipelines", user), name: 'invalid-name'

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
              get api("/projects/#{project.id}/pipelines", user), username: user.username

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response.first['id']).to eq(pipeline.id)
            end
          end

          context 'when username does not exist' do
            it 'returns empty' do
              get api("/projects/#{project.id}/pipelines", user), username: 'invalid-username'

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
              get api("/projects/#{project.id}/pipelines", user), yaml_errors: true

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response.first['id']).to eq(pipeline1.id)
            end
          end

          context 'when yaml_errors is false' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), yaml_errors: false

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response.first['id']).to eq(pipeline2.id)
            end
          end

          context 'when yaml_errors is invalid' do
            it 'returns bad_request' do
              get api("/projects/#{project.id}/pipelines", user), yaml_errors: 'invalid-yaml_errors'

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end

        context 'when order_by and sort are specified' do
          context 'when order_by user_id' do
            before do
              3.times do
                create(:ci_pipeline, project: project, user: create(:user))
              end
            end

            context 'when sort parameter is valid' do
              it 'sorts as user_id: :desc' do
                get api("/projects/#{project.id}/pipelines", user), order_by: 'user_id', sort: 'desc'

                expect(response).to have_gitlab_http_status(:ok)
                expect(response).to include_pagination_headers
                expect(json_response).not_to be_empty

                pipeline_ids = Ci::Pipeline.all.order(user_id: :desc).pluck(:id)
                expect(json_response.map { |r| r['id'] }).to eq(pipeline_ids)
              end
            end

            context 'when sort parameter is invalid' do
              it 'returns bad_request' do
                get api("/projects/#{project.id}/pipelines", user), order_by: 'user_id', sort: 'invalid_sort'

                expect(response).to have_gitlab_http_status(:bad_request)
              end
            end
          end

          context 'when order_by is invalid' do
            it 'returns bad_request' do
              get api("/projects/#{project.id}/pipelines", user), order_by: 'lock_version', sort: 'asc'

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
    context 'authorized user' do
      context 'with gitlab-ci.yml' do
        before do
          stub_ci_pipeline_to_return_yaml_file
        end

        it 'creates and returns a new pipeline' do
          expect do
            post api("/projects/#{project.id}/pipeline", user), ref: project.default_branch
          end.to change { Ci::Pipeline.count }.by(1)

          expect(response).to have_gitlab_http_status(201)
          expect(json_response).to be_a Hash
          expect(json_response['sha']).to eq project.commit.id
        end

        it 'fails when using an invalid ref' do
          post api("/projects/#{project.id}/pipeline", user), ref: 'invalid_ref'

          expect(response).to have_gitlab_http_status(400)
          expect(json_response['message']['base'].first).to eq 'Reference not found'
          expect(json_response).not_to be_an Array
        end
      end

      context 'without gitlab-ci.yml' do
        it 'fails to create pipeline' do
          post api("/projects/#{project.id}/pipeline", user), ref: project.default_branch

          expect(response).to have_gitlab_http_status(400)
          expect(json_response['message']['base'].first).to eq 'Missing .gitlab-ci.yml file'
          expect(json_response).not_to be_an Array
        end
      end
    end

    context 'unauthorized user' do
      it 'does not create pipeline' do
        post api("/projects/#{project.id}/pipeline", non_member), ref: project.default_branch

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response).not_to be_an Array
      end
    end
  end

  describe 'GET /projects/:id/pipelines/:pipeline_id' do
    context 'authorized user' do
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
      it 'should not return a project pipeline' do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}", non_member)

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
          post api("/projects/#{project.id}/pipelines/#{pipeline.id}/retry", user)
        end.to change { pipeline.builds.count }.from(1).to(2)

        expect(response).to have_gitlab_http_status(201)
        expect(build.reload.retried?).to be true
      end
    end

    context 'unauthorized user' do
      it 'should not return a project pipeline' do
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
      it 'retries failed builds' do
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
