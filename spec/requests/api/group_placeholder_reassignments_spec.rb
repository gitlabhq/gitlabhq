# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupPlaceholderReassignments, feature_category: :importers do
  include WorkhorseHelpers

  let_it_be(:group_owner) { create(:user) }
  let(:current_user) { group_owner }
  let_it_be(:group) { create(:group, :public, owners: group_owner) }
  let_it_be(:source_user) { create(:import_source_user, namespace: group) }

  shared_examples 'it has authentication and authorization requirements' do
    context 'when no token supplied' do
      let(:current_user) { nil }

      it 'returns 401' do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when a non-group-owner token is supplied' do
      let(:current_user) { build(:user) }

      it 'returns 403' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'GET /groups/:id/placeholder_reassignments' do
    let(:url) { "/groups/#{group.id}/placeholder_reassignments" }

    subject(:request_csv) { get api(url, current_user) }

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

    it_behaves_like 'it has authentication and authorization requirements'
  end

  describe 'POST /groups/:id/placeholder_reassignments/authorize' do
    include_context 'workhorse headers'

    let(:url) { "/groups/#{group.id}/placeholder_reassignments/authorize" }

    subject(:make_request) { post api(url, current_user), headers: workhorse_headers }

    it 'verifies file size limit' do
      expect(::Import::PlaceholderReassignmentsUploader)
        .to receive(:workhorse_authorize)
        .with(a_hash_including(maximum_size: Gitlab::CurrentSettings.max_attachment_size.megabytes))
        .and_call_original

      make_request
    end

    it 'returns 200' do
      make_request

      expect(response).to have_gitlab_http_status(:ok)
    end

    it_behaves_like 'it has authentication and authorization requirements'
  end

  describe 'POST /groups/:id/placeholder_reassignments' do
    include_context 'workhorse headers'

    let(:url) { "/groups/#{group.id}/placeholder_reassignments" }
    let(:file) { fixture_file_upload('spec/fixtures/import/user_mapping/user_mapping_upload.csv') }

    subject(:make_request) { upload_reassignment_sheet(url, file, workhorse_headers, 'file.size': file.size) }

    it 'returns 201' do
      make_request

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['message'])
        .to eq(s_('UserMapping|The file is being processed and you will receive an email when completed.'))
    end

    it_behaves_like 'it has authentication and authorization requirements'

    context 'when the wrong filetype is uploaded' do
      let(:file) { fixture_file_upload('spec/fixtures/dk.png') }

      it 'rejects the request' do
        make_request

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']).to eq(s_('UserMapping|You must upload a CSV file with a .csv file extension.'))
      end
    end

    context 'when the reassignment service responds with an error' do
      before do
        allow_next_instance_of(Import::SourceUsers::BulkReassignFromCsvService) do |service|
          allow(service).to receive(:async_execute).and_return(ServiceResponse.error(message: 'my error message'))
        end
      end

      it 'passes the error along to the user' do
        make_request

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']).to eq('my error message')
      end
    end

    def upload_reassignment_sheet(url, file, headers = {}, params = {})
      workhorse_finalize(
        api(url, current_user),
        method: :post,
        file_key: :file,
        params: params.merge(file: file),
        headers: headers,
        send_rewritten_field: true
      )
    end
  end
end
