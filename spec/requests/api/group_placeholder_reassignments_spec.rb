# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupPlaceholderReassignments, feature_category: :importers do
  let_it_be(:group_owner) { create(:user) }
  let_it_be(:group) { create(:group, :public, owners: group_owner) }
  let_it_be(:source_user) { create(:import_source_user, namespace: group) }

  describe 'GET /groups/:id/placeholder_reassignments' do
    let(:url) { "/groups/#{group.id}/placeholder_reassignments" }

    subject(:request_csv) { get api(url, group_owner) }

    it 'returns the CSV data' do
      request_csv

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.content_type).to eql('text/csv; charset=utf-8')
      expect(response.headers['Content-Disposition'])
        .to match(/^attachment; filename="placeholder_reassignments_for_group_\d+_\d+.csv"$/)
    end

    context 'when the CSV service returns an error' do
      before do
        allow_next_instance_of(Import::SourceUsers::GenerateCsvService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'my error message'))
        end
      end

      it 'passes the error along to the user' do
        request_csv

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']).to eq('my error message')
      end
    end

    context 'when no token supplied' do
      subject(:request_csv) { get api(url) }

      it 'returns 401' do
        request_csv

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when a non-group-owner token is supplied' do
      subject(:request_csv) { get api(url, build(:user)) }

      it 'returns 403' do
        request_csv

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when importer_user_mapping_reassignment_csv flag is disabled' do
      before do
        stub_feature_flags(importer_user_mapping_reassignment_csv: false)
      end

      it 'returns 404' do
        request_csv

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
