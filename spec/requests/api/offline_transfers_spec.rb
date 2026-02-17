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

  describe 'POST /offline_exports' do
    let(:bucket) { 'exports' }
    let(:entity_params) { [{ 'full_path' => 'group/subgroup' }, { 'full_path' => 'group/project' }] }
    let(:aws_s3_credentials) do
      {
        'aws_access_key_id' => 'AwsUserAccessKey',
        'aws_secret_access_key' => 'aws/secret+access/key',
        'region' => 'us-east-1'
      }
    end

    let(:s3_compatible_credentials) do
      {
        'aws_access_key_id' => 'minio-user-access-key',
        'aws_secret_access_key' => 'minio-secret-access-key',
        'region' => 'gdk',
        'endpoint' => 'https://minio.example.com'
      }
    end

    let(:params) do
      {
        bucket: bucket,
        aws_s3_configuration: aws_s3_credentials,
        entities: entity_params
      }
    end

    subject(:request) { post api('/offline_exports', user), params: params }

    before do
      # Prevents unintentional rate limit errors because the limit for this endpoint is low
      allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(false)
    end

    shared_examples 'starting a new export' do |provider|
      let(:service_response) { instance_double(ServiceResponse, success?: true, payload: export_1) }
      let(:service_double) { instance_double(Import::Offline::Exports::CreateService, execute: service_response) }
      let(:params) do
        {
          bucket: bucket,
          entities: entity_params
        }.merge(configuration_key => credentials)
      end

      before do
        allow(Import::Offline::Exports::CreateService).to receive(:new).and_return(service_double)
      end

      it "starts a new offline export using #{provider} object storage default params" do
        expect(Import::Offline::Exports::CreateService).to receive(:new).with(
          user,
          entity_params,
          {
            bucket: bucket,
            provider: provider,
            credentials: credentials.merge('path_style' => path_style_default)
          },
          current_organization.id
        )

        request

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['id']).to eq(export_1.id)
      end

      context 'when path_style is true' do
        it 'sets true' do
          credentials['path_style'] = true

          expect(Import::Offline::Exports::CreateService).to receive(:new).with(
            user,
            entity_params,
            {
              bucket: bucket,
              provider: provider,
              credentials: credentials
            },
            current_organization.id
          )

          request

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['id']).to eq(export_1.id)
        end
      end

      context 'when path_style is false' do
        it 'sets_false' do
          credentials['path_style'] = false

          expect(Import::Offline::Exports::CreateService).to receive(:new).with(
            user,
            entity_params,
            {
              bucket: bucket,
              provider: provider,
              credentials: credentials
            },
            current_organization.id
          )

          request

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['id']).to eq(export_1.id)
        end
      end
    end

    it_behaves_like 'starting a new export', :aws do
      let(:configuration_key) { :aws_s3_configuration }
      let(:credentials) { aws_s3_credentials }
      let(:path_style_default) { false }
    end

    it_behaves_like 'starting a new export', :s3_compatible do
      let(:configuration_key) { :s3_compatible_configuration }
      let(:credentials) { s3_compatible_credentials }
      let(:path_style_default) { true }
    end

    context 'when no configuration params are provided' do
      let(:params) do
        {
          bucket: bucket,
          entities: entity_params
        }
      end

      it_behaves_like '400 response'
    end

    context 'when more than one provider configuration params are provided' do
      let(:params) do
        {
          bucket: bucket,
          aws_s3_configuration: aws_s3_credentials,
          s3_compatible_configuration: s3_compatible_credentials,
          entities: entity_params
        }
      end

      it_behaves_like '400 response'
    end

    context 'when request exceeds rate limits' do
      it 'prevents user from starting a new migration' do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)

        request

        expect(response).to have_gitlab_http_status(:too_many_requests)
        expect(response.headers).to include('Retry-After' => Gitlab::ApplicationRateLimiter.interval(:offline_export))
        expect(json_response['message']['error']).to eq(
          'This endpoint has been requested too many times. Try again later.'
        )
      end
    end

    context 'when service returns an error' do
      before do
        allow_next_instance_of(Import::Offline::Exports::CreateService) do |service|
          allow(service).to receive(:execute).and_return(
            ServiceResponse.error(message: 'Export failed', reason: :unprocessable_entity)
          )
        end
      end

      it 'renders the error' do
        request

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']).to eq('Export failed')
      end
    end

    it_behaves_like 'not found when offline_transfer_exports is disabled'
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
