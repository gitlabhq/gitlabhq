# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::OfflineTransfers, feature_category: :importers do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:export_1) { create(:offline_export, user: user) }
  let_it_be(:export_2) { create(:offline_export, user: user) }
  let_it_be(:other_user_export) { create(:offline_export) }

  shared_examples 'not found when offline_transfer_exports is disabled' do
    before do
      stub_feature_flags(offline_transfer_exports: false)
    end

    it_behaves_like '404 response'
  end

  describe 'GET /offline_exports' do
    let(:request) { get api('/offline_exports', user), params: params }
    let(:params) { {} }

    it 'returns offline exports authored by the user ordered by created_at descending' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to eq([export_2.id, export_1.id])
    end

    it 'does not return exports from other users' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).not_to include(other_user_export.id)
    end

    context 'with sort parameter' do
      context 'when descending' do
        let(:params) { { sort: 'desc' } }

        it 'sorts by created_at descending' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.pluck('id')).to match_array([export_2.id, export_1.id])
        end
      end

      context 'when ascending' do
        let(:params) { { sort: 'asc' } }

        it 'sorts by created_at ascending when explicitly specified' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.pluck('id')).to match_array([export_1.id, export_2.id])
        end
      end

      context 'when sort is invalid' do
        let(:params) { { sort: 'invalid' } }

        it_behaves_like '400 response'
      end
    end

    context 'with status parameter' do
      let_it_be(:started_export) { create(:offline_export, :started, user: user) }
      let_it_be(:finished_export) { create(:offline_export, :finished, user: user) }
      let_it_be(:failed_export) { create(:offline_export, :failed, user: user) }

      context 'when status is valid' do
        where(:status, :expected_exports) do
          'created'  | [ref(:export_1), ref(:export_2)]
          'started'  | [ref(:started_export)]
          'finished' | [ref(:finished_export)]
          'failed'   | [ref(:failed_export)]
        end

        with_them do
          let(:params) { { status: status } }

          it 'returns only exports with the specified status' do
            request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.pluck('id')).to match_array(expected_exports.map(&:id))
          end
        end
      end

      context 'when status is invalid' do
        let(:params) { { status: 'invalid' } }

        it_behaves_like '400 response'
      end
    end

    it_behaves_like 'not found when offline_transfer_exports is disabled'
  end

  describe 'GET /offline_exports/:id' do
    let(:request) { get api("/offline_exports/#{export_1.id}", user) }

    it 'returns specified offline export' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(export_1.id)
    end

    it 'includes export attributes' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include(
        'id' => export_1.id,
        'status' => export_1.status_name.to_s,
        'source_hostname' => export_1.source_hostname
      )
    end

    context 'when export does not belong to user' do
      let(:request) { get api("/offline_exports/#{other_user_export.id}", user) }

      it_behaves_like '404 response'
    end

    context 'when export does not exist' do
      let(:request) { get api("/offline_exports/#{non_existing_record_id}", user) }

      it_behaves_like '404 response'
    end

    it_behaves_like 'not found when offline_transfer_exports is disabled'
  end

  context 'when user is unauthenticated' do
    let(:request) { get api('/offline_exports', nil) }

    it_behaves_like '401 response'
  end
end
