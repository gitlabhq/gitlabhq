# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::ResourceGroups, feature_category: :continuous_delivery do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let(:user) { developer }

  describe 'GET /projects/:id/resource_groups' do
    subject { get api("/projects/#{project.id}/resource_groups", user) }

    let!(:resource_groups) { create_list(:ci_resource_group, 3, project: project) }

    it 'returns all resource groups for this project', :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      resource_groups.each_index do |i|
        expect(json_response[i]['id']).to eq(resource_groups[i].id)
        expect(json_response[i]['key']).to eq(resource_groups[i].key)
        expect(json_response[i]['process_mode']).to eq(resource_groups[i].process_mode)
        expect(Time.parse(json_response[i]['created_at'])).to be_like_time(resource_groups[i].created_at)
        expect(Time.parse(json_response[i]['updated_at'])).to be_like_time(resource_groups[i].updated_at)
      end
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'GET /projects/:id/resource_groups/:key' do
    subject { get api("/projects/#{project.id}/resource_groups/#{key}", user) }

    let!(:resource_group) { create(:ci_resource_group, project: project) }
    let(:key) { resource_group.key }

    it 'returns a resource group', :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(resource_group.id)
      expect(json_response['key']).to eq(resource_group.key)
      expect(json_response['process_mode']).to eq(resource_group.process_mode)
      expect(Time.parse(json_response['created_at'])).to be_like_time(resource_group.created_at)
      expect(Time.parse(json_response['updated_at'])).to be_like_time(resource_group.updated_at)
    end

    context 'when resource group key contains multiple dots' do
      let!(:resource_group) { create(:ci_resource_group, project: project, key: 'test..test') }

      it 'returns the resource group', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(resource_group.id)
        expect(json_response['key']).to eq(resource_group.key)
      end
    end

    context 'when resource group key contains a slash' do
      let!(:resource_group) { create(:ci_resource_group, project: project, key: 'test/test') }
      let(:key) { 'test%2Ftest' }

      it 'returns the resource group', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(resource_group.id)
        expect(json_response['key']).to eq(resource_group.key)
      end
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when there is no corresponding resource group' do
      let(:key) { 'unknown' }

      it 'returns not found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/resource_groups/:key/upcoming_jobs' do
    subject { get api("/projects/#{project.id}/resource_groups/#{key}/upcoming_jobs", user) }

    let_it_be(:resource_group) { create(:ci_resource_group, project: project) }
    let_it_be(:processable) { create(:ci_processable, resource_group: resource_group) }
    let_it_be(:upcoming_processable) { create(:ci_processable, :waiting_for_resource, resource_group: resource_group) }

    let(:key) { resource_group.key }

    it 'returns upcoming jobs of resource group', :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.length).to eq(1)
      expect(json_response[0]['id']).to eq(upcoming_processable.id)
      expect(json_response[0]['name']).to eq(upcoming_processable.name)
      expect(json_response[0]['ref']).to eq(upcoming_processable.ref)
      expect(json_response[0]['stage']).to eq(upcoming_processable.stage)
      expect(json_response[0]['status']).to eq(upcoming_processable.status)
    end

    context 'when resource group key contains a slash' do
      let_it_be(:resource_group) { create(:ci_resource_group, project: project, key: 'test/test') }
      let_it_be(:upcoming_processable) do
        create(:ci_processable, :waiting_for_resource, resource_group: resource_group)
      end

      let(:key) { 'test%2Ftest' }

      it 'returns the resource group', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response[0]['id']).to eq(upcoming_processable.id)
        expect(json_response[0]['name']).to eq(upcoming_processable.name)
      end
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when there is no corresponding resource group' do
      let(:key) { 'unknown' }

      it 'returns not found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PUT /projects/:id/resource_groups/:key' do
    subject { put api("/projects/#{project.id}/resource_groups/#{key}", user), params: params }

    let!(:resource_group) { create(:ci_resource_group, project: project) }
    let(:key) { resource_group.key }
    let(:params) { { process_mode: :oldest_first } }

    it 'changes the process mode of a resource group' do
      expect { subject }
        .to change { resource_group.reload.process_mode }.from('unordered').to('oldest_first')

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['process_mode']).to eq('oldest_first')
    end

    context 'with invalid parameter' do
      let(:params) { { process_mode: :unknown } }

      it 'returns bad request' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when there is no corresponding resource group' do
      let(:key) { 'unknown' }

      it 'returns not found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
