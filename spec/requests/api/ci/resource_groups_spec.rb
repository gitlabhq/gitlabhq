# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::ResourceGroups do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be(:reporter) { create(:user).tap { |u| project.add_reporter(u) } }

  let(:user) { developer }

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
