# frozen_string_literal: true

require 'spec_helper'

describe API::Deployments do
  let(:user)        { create(:user) }
  let(:non_member)  { create(:user) }

  before do
    project.add_maintainer(user)
  end

  describe 'GET /projects/:id/deployments' do
    let(:project) { create(:project, :repository) }
    let!(:deployment_1) { create(:deployment, :success, project: project, iid: 11, ref: 'master', created_at: Time.now, updated_at: Time.now) }
    let!(:deployment_2) { create(:deployment, :success, project: project, iid: 12, ref: 'master', created_at: 1.day.ago, updated_at: 2.hours.ago) }
    let!(:deployment_3) { create(:deployment, :success, project: project, iid: 8, ref: 'master', created_at: 2.days.ago, updated_at: 1.hour.ago) }

    context 'as member of the project' do
      it 'returns projects deployments sorted by id asc' do
        get api("/projects/#{project.id}/deployments", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(3)
        expect(json_response.first['iid']).to eq(deployment_1.iid)
        expect(json_response.first['sha']).to match /\A\h{40}\z/
        expect(json_response.second['iid']).to eq(deployment_2.iid)
        expect(json_response.last['iid']).to eq(deployment_3.iid)
      end

      context 'with updated_at filters specified' do
        it 'returns projects deployments with last update in specified datetime range' do
          get api("/projects/#{project.id}/deployments", user), params: { updated_before: 30.minutes.ago, updated_after: 90.minutes.ago }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response.first['id']).to eq(deployment_3.id)
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
          expect(json_response.map { |i| i['id'] }).to eq([deployment_2.id, deployment_1.id, deployment_3.id])
        end

        context 'with invalid order_by' do
          let(:order_by) { 'wrong_sorting_value' }

          it 'returns error' do
            expect(response).to have_gitlab_http_status(400)
          end
        end

        context 'with invalid sorting' do
          let(:sort) { 'wrong_sorting_direction' }

          it 'returns error' do
            expect(response).to have_gitlab_http_status(400)
          end
        end
      end
    end

    context 'as non member' do
      it 'returns a 404 status code' do
        get api("/projects/#{project.id}/deployments", non_member)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET /projects/:id/deployments/:deployment_id' do
    let(:project)     { deployment.environment.project }
    let!(:deployment) { create(:deployment, :success) }

    context 'as a member of the project' do
      it 'returns the projects deployment' do
        get api("/projects/#{project.id}/deployments/#{deployment.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['sha']).to match /\A\h{40}\z/
        expect(json_response['id']).to eq(deployment.id)
      end
    end

    context 'as non member' do
      it 'returns a 404 status code' do
        get api("/projects/#{project.id}/deployments/#{deployment.id}", non_member)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'POST /projects/:id/deployments' do
    let!(:project) { create(:project, :repository) }
    let(:sha) { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }

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

        expect(response).to have_gitlab_http_status(201)

        expect(json_response['sha']).to eq(sha)
        expect(json_response['ref']).to eq('master')
        expect(json_response['environment']['name']).to eq('production')
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

        expect(response).to have_gitlab_http_status(500)
      end

      it 'links any merged merge requests to the deployment', :sidekiq_inline do
        mr = create(
          :merge_request,
          :merged,
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

        expect(response).to have_gitlab_http_status(201)

        expect(json_response['sha']).to eq(sha)
        expect(json_response['ref']).to eq('master')
      end

      it 'links any merged merge requests to the deployment', :sidekiq_inline do
        mr = create(
          :merge_request,
          :merged,
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
    end

    context 'as non member' do
      it 'returns a 404 status code' do
        post(
          api( "/projects/#{project.id}/deployments", non_member),
          params: {
            environment: 'production',
            sha: '123',
            ref: 'master',
            tag: false,
            status: 'success'
          }
        )

        expect(response).to have_gitlab_http_status(404)
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

    context 'as a maintainer' do
      it 'returns a 403 when updating a deployment with a build' do
        deploy.update(deployable: build)

        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", user),
          params: { status: 'success' }
        )

        expect(response).to have_gitlab_http_status(403)
      end

      it 'updates a deployment without an associated build' do
        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", user),
          params: { status: 'success' }
        )

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['status']).to eq('success')
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
        deploy.update(deployable: build)

        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", developer),
          params: { status: 'success' }
        )

        expect(response).to have_gitlab_http_status(403)
      end

      it 'updates a deployment without an associated build' do
        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", developer),
          params: { status: 'success' }
        )

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['status']).to eq('success')
      end
    end

    context 'as non member' do
      it 'returns a 404 status code' do
        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", non_member),
          params: { status: 'success' }
        )

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET /projects/:id/deployments/:deployment_id/merge_requests' do
    let(:project) { create(:project, :repository) }
    let!(:deployment) { create(:deployment, :success, project: project) }

    subject { get api("/projects/#{project.id}/deployments/#{deployment.id}/merge_requests", user) }

    context 'when a user is not a member of the deployment project' do
      let(:user) { build(:user) }

      it 'returns a 404 status code' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when a user member of the deployment project' do
      let_it_be(:project2) { create(:project) }
      let!(:merge_request1) { create(:merge_request, source_project: project, target_project: project) }
      let!(:merge_request2) { create(:merge_request, source_project: project, target_project: project, state: 'closed') }
      let!(:merge_request3) { create(:merge_request, source_project: project2, target_project: project2) }

      it 'returns the relevant merge requests linked to a deployment for a project' do
        deployment.merge_requests << [merge_request1, merge_request2]

        subject

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.map { |d| d['id'] }).to contain_exactly(merge_request1.id, merge_request2.id)
      end

      context 'when a deployment is not associated to any existing merge requests' do
        it 'returns an empty array' do
          subject

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to eq([])
        end
      end
    end
  end

  context 'prevent N + 1 queries' do
    context 'when the endpoint returns multiple records' do
      let(:project) { create(:project, :repository) }
      let!(:deployment) { create(:deployment, :success, project: project) }

      subject { get api("/projects/#{project.id}/deployments?order_by=updated_at&sort=asc", user) }

      it 'succeeds', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(200)
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
