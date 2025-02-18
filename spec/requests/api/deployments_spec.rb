# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Deployments, feature_category: :continuous_delivery do
  let_it_be(:user)        { create(:user) }
  let_it_be(:non_member)  { create(:user) }

  before do
    project.add_maintainer(user)
  end

  describe 'GET /projects/:id/deployments' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:production) { create(:environment, :production, project: project) }
    let_it_be(:staging) { create(:environment, :staging, project: project) }
    let_it_be(:build) { create(:ci_build, :success, project: project) }
    let_it_be(:deployment_1) { create(:deployment, :success, project: project, environment: production, deployable: build, ref: 'master', created_at: Time.now, updated_at: Time.now) }
    let_it_be(:deployment_2) { create(:deployment, :success, project: project, environment: staging, deployable: build, ref: 'master', created_at: 1.day.ago, finished_at: 2.hours.ago, updated_at: 2.hours.ago) }
    let_it_be(:deployment_3) { create(:deployment, :success, project: project, environment: staging, deployable: build, ref: 'master', created_at: 2.days.ago, finished_at: 1.hour.ago, updated_at: 1.hour.ago) }

    def perform_request(params = {})
      get api("/projects/#{project.id}/deployments", user), params: params
    end

    it_behaves_like 'enforcing job token policies', :read_deployments do
      let(:request) do
        get api("/projects/#{source_project.id}/deployments"), params: { job_token: target_job.token }
      end
    end

    context 'as member of the project' do
      it 'returns projects deployments sorted by id asc' do
        perform_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(3)
        expect(json_response.first['iid']).to eq(deployment_1.iid)
        expect(json_response.first['sha']).to match(/\A\h{40}\z/)
        expect(json_response.second['iid']).to eq(deployment_2.iid)
        expect(json_response.last['iid']).to eq(deployment_3.iid)
      end

      context 'with updated_at filters specified' do
        context 'when using `order_by=updated_at`' do
          it 'returns projects deployments with last update in specified datetime range' do
            perform_request({ updated_before: 30.minutes.ago, updated_after: 90.minutes.ago, order_by: :updated_at })

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response.first['id']).to eq(deployment_3.id)
          end
        end

        context 'when not using `order_by=updated_at`' do
          it 'returns an error' do
            perform_request({ updated_before: 30.minutes.ago, updated_after: 90.minutes.ago, order_by: :id })

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to include('`updated_at` filter requires `updated_at` sort')
          end
        end
      end

      context 'with finished after and before filters specified' do
        context 'for successful deployments' do
          it 'returns projects deployments finished before the specified datetime range' do
            perform_request({ status: :success, finished_before: 90.minutes.ago, order_by: :finished_at, environment: 'staging' })

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response.first['id']).to eq(deployment_2.id)
          end

          it 'returns projects deployments finished after the specified datetime range' do
            perform_request({ status: :success, finished_after: 90.minutes.ago, order_by: :finished_at, environment: 'staging' })

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response.first['id']).to eq(deployment_3.id)
          end
        end

        context 'for unsuccessful deployments' do
          it 'returns an error' do
            perform_request({ status: :failed, finished_before: 30.minutes.ago, order_by: :finished_at })

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to include('`finished_at` filter must be combined with `success` status filter.')
          end
        end

        context 'when a forbidden order_by is specified' do
          it 'returns an error' do
            perform_request({ status: :success, finished_before: 30.minutes.ago, order_by: :id })

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to include('`finished_at` filter requires `finished_at` sort.')
          end
        end
      end

      context 'with the environment filter specifed' do
        it 'returns deployments for the environment' do
          perform_request({ environment: production.name })

          expect(json_response.size).to eq(1)
          expect(json_response.first['iid']).to eq(deployment_1.iid)
        end
      end

      describe 'ordering' do
        let(:order_by) { 'iid' }
        let(:sort) { 'desc' }

        subject { get api("/projects/#{project.id}/deployments?order_by=#{order_by}&sort=#{sort}", user) }

        before do
          subject
        end

        def expect_deployments(ordered_deployments)
          expect(json_response.map { |d| d['id'] }).to eq(ordered_deployments.map(&:id))
        end

        it 'returns ordered deployments' do
          expect(json_response.map { |i| i['id'] }).to eq([deployment_3.id, deployment_2.id, deployment_1.id])
        end

        context 'with invalid order_by' do
          let(:order_by) { 'wrong_sorting_value' }

          it 'returns error' do
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context 'with invalid sorting' do
          let(:sort) { 'wrong_sorting_direction' }

          it 'returns error' do
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      it 'returns multiple deployments without N + 1' do
        perform_request # warm up the cache

        control = ActiveRecord::QueryRecorder.new { perform_request }

        create(:deployment, :success, project: project, deployable: build, iid: 21, ref: 'master')

        expect { perform_request }.not_to exceed_query_limit(control)
      end
    end

    context 'as non member' do
      it 'returns a 404 status code' do
        get api("/projects/#{project.id}/deployments", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/deployments/:deployment_id' do
    let_it_be(:deployment_with_bridge) { create(:deployment, :with_bridge, :success) }
    let_it_be(:deployment_with_build) { create(:deployment, :success) }

    context 'as a member of the project' do
      shared_examples "returns project deployments" do
        let(:project) { deployment.environment.project }

        it_behaves_like 'enforcing job token policies', :read_deployments do
          let(:request) do
            get api("/projects/#{source_project.id}/deployments/#{deployment.id}"),
              params: { job_token: target_job.token }
          end
        end

        it 'returns the expected response' do
          get api("/projects/#{project.id}/deployments/#{deployment.id}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['sha']).to match(/\A\h{40}\z/)
          expect(json_response['id']).to eq(deployment.id)
        end
      end

      context 'when the deployable is a build' do
        it_behaves_like 'returns project deployments' do
          let!(:deployment) { deployment_with_build }
        end
      end

      context 'when the deployable is a bridge' do
        it_behaves_like 'returns project deployments' do
          let!(:deployment) { deployment_with_bridge }
        end
      end
    end

    context 'as non member' do
      shared_examples 'deployment will not be found' do
        let(:project) { deployment.environment.project }

        it 'returns a 404 status code' do
          get api("/projects/#{project.id}/deployments/#{deployment.id}", non_member)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the deployable is a build' do
        it_behaves_like 'deployment will not be found' do
          let!(:deployment) { deployment_with_build }
        end
      end

      context 'when the deployable is a bridge' do
        it_behaves_like 'deployment will not be found' do
          let!(:deployment) { deployment_with_bridge }
        end
      end
    end
  end

  describe 'POST /projects/:id/deployments' do
    let!(:project) { create(:project, :repository) }
    # *   ddd0f15ae83993f5cb66a927a28673882e99100b (HEAD -> master, origin/master, origin/HEAD) Merge branch 'po-fix-test-en
    # |\
    # | * 2d1db523e11e777e49377cfb22d368deec3f0793 Correct test_env.rb path for adding branch
    # |/
    # *   1e292f8fedd741b75372e19097c76d327140c312 Merge branch 'cherry-pick-ce369011' into 'master'

    let_it_be(:sha) { 'ddd0f15ae83993f5cb66a927a28673882e99100b' }
    let_it_be(:first_deployment_sha) { '1e292f8fedd741b75372e19097c76d327140c312' }

    before do
      # Creating the first deployment is an edge-case that is already covered by unit testing,
      # here we want to see the behavior of a running system so we create a first deployment
      post(
        api("/projects/#{project.id}/deployments", user),
        params: {
          environment: 'production',
          sha: first_deployment_sha,
          ref: 'master',
          tag: false,
          status: 'success'
        }
      )
    end

    it_behaves_like 'enforcing job token policies', [:admin_deployments, :admin_environments] do
      let(:request) do
        post(
          api("/projects/#{source_project.id}/deployments"),
          params: {
            job_token: target_job.token,
            environment: 'production',
            sha: sha,
            ref: 'master',
            tag: false,
            status: 'success'
          }
        )
      end
    end

    context 'as a maintainer' do
      it 'creates a new deployment' do
        post(
          api("/projects/#{project.id}/deployments", user),
          params: {
            environment: 'production',
            sha: sha,
            ref: 'master',
            tag: false,
            status: 'success'
          }
        )

        expect(response).to have_gitlab_http_status(:created)

        expect(json_response['sha']).to eq(sha)
        expect(json_response['ref']).to eq('master')
        expect(json_response['environment']['name']).to eq('production')
      end

      it 'errors when creating a deployment with an invalid ref', :aggregate_failures do
        post(
          api("/projects/#{project.id}/deployments", user),
          params: {
            environment: 'production',
            sha: sha,
            ref: 'doesnotexist',
            tag: false,
            status: 'success'
          }
        )

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq({ "ref" => ["The branch or tag does not exist"] })
      end

      it 'errors when creating a deployment with an invalid name' do
        post(
          api("/projects/#{project.id}/deployments", user),
          params: {
            environment: 'a' * 300,
            sha: sha,
            ref: 'master',
            tag: false,
            status: 'success'
          }
        )

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'links any merged merge requests to the deployment', :sidekiq_inline do
        mr = create(
          :merge_request,
          :merged,
          merge_commit_sha: sha,
          target_project: project,
          source_project: project,
          target_branch: 'master',
          source_branch: 'foo'
        )

        post(
          api("/projects/#{project.id}/deployments", user),
          params: {
            environment: 'production',
            sha: sha,
            ref: 'master',
            tag: false,
            status: 'success'
          }
        )

        deploy = project.deployments.last

        expect(deploy.merge_requests).to eq([mr])
      end
    end

    context 'as a developer' do
      let(:developer) { create(:user) }

      before do
        project.add_developer(developer)
      end

      it 'creates a new deployment' do
        post(
          api("/projects/#{project.id}/deployments", developer),
          params: {
            environment: 'production',
            sha: sha,
            ref: 'master',
            tag: false,
            status: 'success'
          }
        )

        expect(response).to have_gitlab_http_status(:created)

        expect(json_response['sha']).to eq(sha)
        expect(json_response['ref']).to eq('master')
      end

      it 'links any merged merge requests to the deployment', :sidekiq_inline do
        mr = create(
          :merge_request,
          :merged,
          merge_commit_sha: sha,
          target_project: project,
          source_project: project,
          target_branch: 'master',
          source_branch: 'foo'
        )

        post(
          api("/projects/#{project.id}/deployments", developer),
          params: {
            environment: 'production',
            sha: sha,
            ref: 'master',
            tag: false,
            status: 'success'
          }
        )

        deploy = project.deployments.last

        expect(deploy.merge_requests).to eq([mr])
      end

      it 'links any picked merge requests to the deployment', :sidekiq_inline do
        mr = create(
          :merge_request,
          :merged,
          merge_commit_sha: sha,
          target_project: project,
          source_project: project,
          target_branch: 'master',
          source_branch: 'foo'
        )

        # we branch from the previous deployment and cherry-pick mr into the new branch
        branch = project.repository.add_branch(developer, 'stable', first_deployment_sha)
        expect(branch).not_to be_nil

        result = ::Commits::CherryPickService
                   .new(project, developer, commit: mr.merge_commit, start_branch: 'stable', branch_name: 'stable')
                   .execute
        expect(result[:status]).to eq(:success), result[:message]

        pick_sha = result[:result]

        post(
          api("/projects/#{project.id}/deployments", developer),
          params: {
            environment: 'production',
            sha: pick_sha,
            ref: 'stable',
            tag: false,
            status: 'success'
          }
        )

        deploy = project.deployments.last
        expect(deploy.merge_requests).to eq([mr])
      end
    end

    context 'as non member' do
      it 'returns a 404 status code' do
        post(
          api("/projects/#{project.id}/deployments", non_member),
          params: {
            environment: 'production',
            sha: '123',
            ref: 'master',
            tag: false,
            status: 'success'
          }
        )

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PUT /projects/:id/deployments/:deployment_id' do
    let(:project) { create(:project, :repository) }
    let(:build) { create(:ci_build, :failed, project: project) }
    let(:environment) { create(:environment, project: project) }
    let(:deploy) do
      create(
        :deployment,
        :failed,
        project: project,
        environment: environment,
        deployable: nil,
        sha: project.commit.sha
      )
    end

    it_behaves_like 'enforcing job token policies', :admin_deployments do
      let(:request) do
        put api("/projects/#{source_project.id}/deployments/#{deploy.id}"),
          params: { status: 'success', job_token: target_job.token }
      end
    end

    context 'as a maintainer' do
      it 'returns a 403 when updating a deployment with a build' do
        deploy.update!(deployable: build)

        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", user),
          params: { status: 'success' }
        )

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'updates a deployment without an associated build' do
        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", user),
          params: { status: 'success' }
        )

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['status']).to eq('success')
      end

      it 'returns an error when an invalid status transition is detected' do
        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", user),
          params: { status: 'running' }
        )

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['status']).to include(%(cannot transition via \"run\"))
      end

      it 'links merge requests when the deployment status changes to success', :sidekiq_inline do
        mr = create(
          :merge_request,
          :merged,
          target_project: project,
          source_project: project,
          target_branch: 'master',
          source_branch: 'foo'
        )

        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", user),
          params: { status: 'success' }
        )

        deploy = project.deployments.last

        expect(deploy.merge_requests).to eq([mr])
      end
    end

    context 'as a developer' do
      let(:developer) { create(:user) }

      before do
        project.add_developer(developer)
      end

      it 'returns a 403 when updating a deployment with a build' do
        deploy.update!(deployable: build)

        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", developer),
          params: { status: 'success' }
        )

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'updates a deployment without an associated build' do
        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", developer),
          params: { status: 'success' }
        )

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['status']).to eq('success')
      end
    end

    context 'as non member' do
      it 'returns a 404 status code' do
        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", non_member),
          params: { status: 'success' }
        )

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /projects/:id/deployments/:deployment_id' do
    let(:project) { create(:project, :repository) }
    let(:environment) { create(:environment, project: project) }
    let(:commits) { project.repository.commits(nil, { limit: 3 }) }
    let!(:deploy) do
      create(
        :deployment,
        :success,
        project: project,
        environment: environment,
        deployable: nil,
        sha: commits[1].sha
      )
    end

    let!(:old_deploy) do
      create(
        :deployment,
        :success,
        project: project,
        environment: environment,
        deployable: nil,
        sha: commits[0].sha,
        finished_at: 1.year.ago
      )
    end

    let!(:running_deploy) do
      create(
        :deployment,
        :running,
        project: project,
        environment: environment,
        deployable: nil,
        sha: commits[2].sha
      )
    end

    it_behaves_like 'enforcing job token policies', :admin_deployments do
      let(:request) do
        delete api("/projects/#{source_project.id}/deployments/#{old_deploy.id}"),
          params: { job_token: target_job.token }
      end
    end

    context 'as an maintainer' do
      it 'deletes a deployment' do
        delete api("/projects/#{project.id}/deployments/#{old_deploy.id}", user)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it 'will not delete a running deployment' do
        delete api("/projects/#{project.id}/deployments/#{running_deploy.id}", user)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.body).to include("Cannot destroy running deployment")
      end
    end

    context 'as a developer' do
      let(:developer) { create(:user) }

      before do
        project.add_developer(developer)
      end

      it 'is forbidden' do
        delete api("/projects/#{project.id}/deployments/#{deploy.id}", developer)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'as non member' do
      it 'is not found' do
        delete api("/projects/#{project.id}/deployments/#{deploy.id}", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'for non-existent deployment' do
      it 'is not found' do
        delete api("/projects/#{project.id}/deployments/#{non_existing_record_id}", project.first_owner)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/deployments/:deployment_id/merge_requests' do
    let(:project) { create(:project, :repository) }
    let!(:deployment) { create(:deployment, :success, project: project) }

    subject { get api("/projects/#{project.id}/deployments/#{deployment.id}/merge_requests", user) }

    it_behaves_like 'enforcing job token policies', :read_deployments do
      let(:request) do
        get api("/projects/#{source_project.id}/deployments/#{deployment.id}/merge_requests"), params: { job_token: target_job.token }
      end
    end

    context 'when a user is not a member of the deployment project' do
      let(:user) { build(:user) }

      it 'returns a 404 status code' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when a user member of the deployment project' do
      let_it_be(:project2) { create(:project) }

      let!(:merge_request1) { create(:merge_request, source_project: project, target_project: project) }
      let!(:merge_request2) { create(:merge_request, source_project: project, target_project: project, state: 'closed') }
      let!(:merge_request3) { create(:merge_request, source_project: project2, target_project: project2) }

      it 'returns the relevant merge requests linked to a deployment for a project' do
        deployment.link_merge_requests(MergeRequest.where(id: [merge_request1.id, merge_request2.id]))

        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.map { |d| d['id'] }).to contain_exactly(merge_request1.id, merge_request2.id)
      end

      context 'when a deployment is not associated to any existing merge requests' do
        it 'returns an empty array' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq([])
        end
      end
    end
  end

  context 'prevent N + 1 queries' do
    context 'when the endpoint returns multiple records' do
      let(:project) { create(:project, :repository) }
      let!(:deployment) { create(:deployment, :success, project: project) }

      subject { get api("/projects/#{project.id}/deployments?order_by=id&sort=asc", user) }

      it 'succeeds', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(1)
      end

      context 'with 10 more records' do
        it 'does not increase the query count', :aggregate_failures do
          create_list(:deployment, 10, :success, project: project)

          expect { subject }.not_to be_n_plus_1_query

          expect(json_response.size).to eq(11)
        end
      end
    end
  end
end
