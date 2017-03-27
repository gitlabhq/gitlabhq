require 'spec_helper'

describe API::Pipelines do
  let(:user)        { create(:user) }
  let(:non_member)  { create(:user) }
  let(:project)     { create(:project, :repository, creator: user) }

  let!(:pipeline) do
    create(:ci_empty_pipeline, project: project, sha: project.commit.id,
                               ref: project.default_branch)
  end

  before { project.team << [user, :master] }

  describe 'GET /projects/:id/pipelines ' do
    context 'authorized user' do
      it 'returns project pipelines' do
        get api("/projects/#{project.id}/pipelines", user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['sha']).to match /\A\h{40}\z/
        expect(json_response.first['id']).to eq pipeline.id
        expect(json_response.first.keys).to contain_exactly(*%w[id sha ref status])
      end

      context 'when parameter is passed' do
        let(:user1) { create(:user) }
        let(:user2) { create(:user) }
        let(:project) { create(:project, :repository) }

        before do
          create(:ci_pipeline, project: project, user: user1, ref: 'v1.0.0', tag: true)
          create(:ci_pipeline, project: project, user: user1, status: 'created')
          create(:ci_pipeline, project: project, user: user1, status: 'pending')
          create(:ci_pipeline, project: project, user: user1, status: 'running')
          create(:ci_pipeline, project: project, user: user1, status: 'success')
          create(:ci_pipeline, project: project, user: user2, status: 'failed')
          create(:ci_pipeline, project: project, user: user2, status: 'canceled')
          create(:ci_pipeline, project: project, user: user2, status: 'skipped')
          create(:ci_pipeline, project: project, user: user2, yaml_errors: 'Syntax error')
        end

        context 'when scope is passed' do
          %w[running pending].each do |target|
            context "when scope is #{target}" do
              it "returns matched pipelines" do
                get api("/projects/#{project.id}/pipelines", user), scope: target

                expect(response).to have_http_status(200)
                expect(response).to include_pagination_headers
                expect(json_response).not_to be_empty
                json_response.each { |r| expect(r['status']).to eq(target) }
              end
            end
          end

          context 'when scope is finished' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), scope: 'finished'

              expect(response).to have_http_status(200)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              json_response.each { |r| expect(r['status']).to be_in(%w[success failed canceled]) }
            end
          end

          context 'when scope is branches' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), scope: 'branches'

              expect(response).to have_http_status(200)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              expect(json_response.last['sha']).to eq(project.pipelines.where(tag: false).last.sha)
            end
          end

          context 'when scope is tags' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), scope: 'tags'

              expect(response).to have_http_status(200)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              expect(json_response.last['sha']).to eq(project.pipelines.where(tag: true).last.sha)
            end
          end

          context 'when scope is invalid' do
            it 'returns 400' do
              get api("/projects/#{project.id}/pipelines", user), scope: 'invalid-scope'

              expect(response).to have_http_status(400)
            end
          end
        end

        context 'when status is passed' do
          %w[running pending success failed canceled skipped].each do |target|
            context "when status is #{target}" do
              it 'returns matched pipelines' do
                get api("/projects/#{project.id}/pipelines", user), status: target

                expect(response).to have_http_status(200)
                expect(response).to include_pagination_headers
                expect(json_response).not_to be_empty
                json_response.each { |r| expect(r['status']).to eq(target) }
              end
            end
          end

          context 'when status is invalid' do
            it 'returns 400' do
              get api("/projects/#{project.id}/pipelines", user), status: 'invalid-status'

              expect(response).to have_http_status(400)
            end
          end
        end

        context 'when ref is passed' do
          context 'when ref exists' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), ref: 'master'

              expect(response).to have_http_status(200)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              json_response.each { |r| expect(r['ref']).to eq('master') }
            end
          end

          context 'when ref does not exist' do
            it 'returns empty' do
              get api("/projects/#{project.id}/pipelines", user), ref: 'invalid-ref'

              expect(response).to have_http_status(200)
              expect(response).to include_pagination_headers
              expect(json_response).to be_empty
            end
          end
        end

        context 'when name is passed' do
          context 'when name exists' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), name: user1.name

              expect(response).to have_http_status(200)
              expect(response).to include_pagination_headers
              expect(json_response.first['sha']).to eq(project.pipelines.where(user: user1).order(id: :desc).first.sha)
            end
          end

          context 'when name does not exist' do
            it 'returns empty' do
              get api("/projects/#{project.id}/pipelines", user), name: 'invalid-name'

              expect(response).to have_http_status(200)
              expect(response).to include_pagination_headers
              expect(json_response).to be_empty
            end
          end
        end

        context 'when username is passed' do
          context 'when username exists' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), username: user1.username

              expect(response).to have_http_status(200)
              expect(response).to include_pagination_headers
              expect(json_response.first['sha']).to eq(project.pipelines.where(user: user1).order(id: :desc).first.sha)
            end
          end

          context 'when username does not exist' do
            it 'returns empty' do
              get api("/projects/#{project.id}/pipelines", user), username: 'invalid-username'

              expect(response).to have_http_status(200)
              expect(response).to include_pagination_headers
              expect(json_response).to be_empty
            end
          end
        end

        context 'when yaml_errors is passed' do
          context 'when yaml_errors is true' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), yaml_errors: true

              expect(response).to have_http_status(200)
              expect(response).to include_pagination_headers
              expect(json_response.first['id']).to eq(project.pipelines.where("yaml_errors IS NOT NULL").order(id: :desc).first.id)
            end
          end

          context 'when yaml_errors is false' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), yaml_errors: false

              expect(response).to have_http_status(200)
              expect(response).to include_pagination_headers
              expect(json_response.first['id']).to eq(project.pipelines.where("yaml_errors IS NULL").order(id: :desc).first.id)
            end
          end

          context 'when yaml_errors is invalid' do
            it 'returns 400' do
              get api("/projects/#{project.id}/pipelines", user), yaml_errors: 'invalid-yaml_errors'

              expect(response).to have_http_status(400)
            end
          end
        end

        context 'when order_by and sort are passed' do
          context 'when order_by and sort are valid' do
            it 'sorts pipelines' do
              get api("/projects/#{project.id}/pipelines", user), order_by: 'user_id', sort: 'asc'

              expect(response).to have_http_status(200)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              pipelines = project.pipelines.order(user_id: :asc)
              json_response.each_with_index do |r, i|
                expect(r['id']).to eq(pipelines[i].id)
              end
            end
          end

          context 'when order_by is invalid' do
            it 'returns 400' do
              get api("/projects/#{project.id}/pipelines", user), order_by: 'lock_version', sort: 'asc'

              expect(response).to have_http_status(400)
            end
          end

          context 'when sort is invalid' do
            it 'returns 400' do
              get api("/projects/#{project.id}/pipelines", user), order_by: 'id', sort: 'hack'

              expect(response).to have_http_status(400)
            end
          end
        end
      end
    end

    context 'unauthorized user' do
      it 'does not return project pipelines' do
        get api("/projects/#{project.id}/pipelines", non_member)

        expect(response).to have_http_status(404)
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
            post api("/projects/#{project.id}/pipeline", user), ref: project.default_branch
          end.to change { Ci::Pipeline.count }.by(1)

          expect(response).to have_http_status(201)
          expect(json_response).to be_a Hash
          expect(json_response['sha']).to eq project.commit.id
        end

        it 'fails when using an invalid ref' do
          post api("/projects/#{project.id}/pipeline", user), ref: 'invalid_ref'

          expect(response).to have_http_status(400)
          expect(json_response['message']['base'].first).to eq 'Reference not found'
          expect(json_response).not_to be_an Array
        end
      end

      context 'without gitlab-ci.yml' do
        it 'fails to create pipeline' do
          post api("/projects/#{project.id}/pipeline", user), ref: project.default_branch

          expect(response).to have_http_status(400)
          expect(json_response['message']['base'].first).to eq 'Missing .gitlab-ci.yml file'
          expect(json_response).not_to be_an Array
        end
      end
    end

    context 'unauthorized user' do
      it 'does not create pipeline' do
        post api("/projects/#{project.id}/pipeline", non_member), ref: project.default_branch

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response).not_to be_an Array
      end
    end
  end

  describe 'GET /projects/:id/pipelines/:pipeline_id' do
    context 'authorized user' do
      it 'returns project pipelines' do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}", user)

        expect(response).to have_http_status(200)
        expect(json_response['sha']).to match /\A\h{40}\z/
      end

      it 'returns 404 when it does not exist' do
        get api("/projects/#{project.id}/pipelines/123456", user)

        expect(response).to have_http_status(404)
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

        expect(response).to have_http_status(404)
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

        expect(response).to have_http_status(201)
        expect(build.reload.retried?).to be true
      end
    end

    context 'unauthorized user' do
      it 'should not return a project pipeline' do
        post api("/projects/#{project.id}/pipelines/#{pipeline.id}/retry", non_member)

        expect(response).to have_http_status(404)
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

        expect(response).to have_http_status(200)
        expect(json_response['status']).to eq('canceled')
      end
    end

    context 'user without proper access rights' do
      let!(:reporter) { create(:user) }

      before { project.team << [reporter, :reporter] }

      it 'rejects the action' do
        post api("/projects/#{project.id}/pipelines/#{pipeline.id}/cancel", reporter)

        expect(response).to have_http_status(403)
        expect(pipeline.reload.status).to eq('pending')
      end
    end
  end
end
