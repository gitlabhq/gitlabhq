require 'spec_helper'

describe API::Deployments do
  let(:user)        { create(:user) }
  let(:non_member)  { create(:user) }

  before do
    project.add_master(user)
  end

  describe 'GET /projects/:id/deployments' do
    let(:project) { create(:project) }
    let!(:deployment_1) { create(:deployment, project: project, iid: 11, ref: 'master', created_at: Time.now) }
    let!(:deployment_2) { create(:deployment, project: project, iid: 12, ref: 'feature', created_at: 1.day.ago) }
    let!(:deployment_3) { create(:deployment, project: project, iid: 8, ref: 'feature', created_at: 2.days.ago) }

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
          'ref'        | 'asc'  | [:deployment_2, :deployment_3, :deployment_1]
          'ref'        | 'desc' | [:deployment_1, :deployment_2, :deployment_3]
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
    let!(:deployment) { create(:deployment) }

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
end
