# frozen_string_literal: true

require 'spec_helper'

describe API::Deployments do
  let(:user)        { create(:user) }
  let(:non_member)  { create(:user) }

  before do
    project.add_maintainer(user)
  end

  describe 'GET /projects/:id/deployments' do
    let(:project) { create(:project) }
    let!(:deployment_1) { create(:deployment, :success, project: project, iid: 11, ref: 'master', created_at: Time.now) }
    let!(:deployment_2) { create(:deployment, :success, project: project, iid: 12, ref: 'feature', created_at: 1.day.ago) }
    let!(:deployment_3) { create(:deployment, :success, project: project, iid: 8, ref: 'patch', created_at: 2.days.ago) }

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

      describe 'ordering' do
        using RSpec::Parameterized::TableSyntax

        let(:order_by) { nil }
        let(:sort) { nil }

        subject { get api("/projects/#{project.id}/deployments?order_by=#{order_by}&sort=#{sort}", user) }

        def expect_deployments(ordered_deployments)
          json_response.each_with_index do |deployment_json, index|
            expect(deployment_json['id']).to eq(public_send(ordered_deployments[index]).id)
          end
        end

        before do
          subject
        end

        where(:order_by, :sort, :ordered_deployments) do
          'created_at' | 'asc'  | [:deployment_3, :deployment_2, :deployment_1]
          'created_at' | 'desc' | [:deployment_1, :deployment_2, :deployment_3]
          'id'         | 'asc'  | [:deployment_1, :deployment_2, :deployment_3]
          'id'         | 'desc' | [:deployment_3, :deployment_2, :deployment_1]
          'iid'        | 'asc'  | [:deployment_3, :deployment_1, :deployment_2]
          'iid'        | 'desc' | [:deployment_2, :deployment_1, :deployment_3]
          'ref'        | 'asc'  | [:deployment_2, :deployment_1, :deployment_3]
          'ref'        | 'desc' | [:deployment_3, :deployment_1, :deployment_2]
        end

        with_them do
          it 'returns the deployments ordered' do
            expect_deployments(ordered_deployments)
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

      it 'links any merged merge requests to the deployment' do
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

      it 'links any merged merge requests to the deployment' do
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
end
