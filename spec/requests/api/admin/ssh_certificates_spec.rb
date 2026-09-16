# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::SshCertificates, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let(:current_user) { admin }
  let(:admin_mode) { true }
  let(:params) { {} }

  subject(:perform_request) do
    public_send(http_method, api(path, current_user, admin_mode: admin_mode), params: params)
  end

  shared_examples 'rejects unauthorized certificate requests' do
    where(:current_user, :admin_mode, :expected_status) do
      nil         | false | :unauthorized
      ref(:user)  | true  | :forbidden
      ref(:admin) | false | :forbidden
    end

    with_them do
      it 'rejects the request without changing certificates', :aggregate_failures do
        expect { perform_request }.not_to change { InstanceSshCertificate.count }

        expect(response).to have_gitlab_http_status(expected_status)
      end
    end
  end

  shared_examples 'an unavailable certificate endpoint' do
    it 'returns not found without changing certificates', :aggregate_failures do
      expect { perform_request }.not_to change { InstanceSshCertificate.count }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it_behaves_like 'rejects unauthorized certificate requests'
  end

  shared_examples 'an admin-only instance certificate endpoint' do
    it_behaves_like 'rejects unauthorized certificate requests'

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(instance_ssh_certificates: false)
      end

      it_behaves_like 'an unavailable certificate endpoint'
    end

    context 'on GitLab.com', :saas do
      it_behaves_like 'an unavailable certificate endpoint'
    end
  end

  describe 'GET /admin/ssh_certificates' do
    let(:path) { '/admin/ssh_certificates' }
    let(:http_method) { :get }

    it_behaves_like 'an admin-only instance certificate endpoint'

    it 'returns an empty list' do
      perform_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq([])
    end

    context 'when certificates exist' do
      let_it_be(:certificate) { create(:instance_ssh_certificate, key: build(:rsa_key_4096).key) }
      let_it_be(:other_certificate) { create(:instance_ssh_certificate, key: build(:rsa_key_5120).key) }

      it 'returns certificates in descending ID order', :aggregate_failures do
        perform_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.pluck('id')).to eq([other_certificate.id, certificate.id])
        expect(json_response.last).to match(
          'id' => certificate.id,
          'title' => certificate.title,
          'key' => certificate.key,
          'created_at' => certificate.created_at.as_json
        )
      end

      context 'with pagination' do
        let(:params) { { per_page: 1, page: 2 } }

        it 'returns only the requested page', :aggregate_failures do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response.pluck('id')).to eq([certificate.id])
        end
      end

      it 'does not add queries for additional certificates' do
        get api(path, admin, admin_mode: true)

        control = ActiveRecord::QueryRecorder.new { get api(path, admin, admin_mode: true) }
        create(:instance_ssh_certificate, key: build(:rsa_key_8192).key)

        expect { get api(path, admin, admin_mode: true) }.not_to exceed_query_limit(control)
      end
    end

    it_behaves_like 'authorizing granular token permissions', :read_ssh_certificate do
      let(:user) { admin }
      let(:boundary_object) { :instance }
      let(:request) { get api(path, personal_access_token: pat) }
    end
  end

  describe 'POST /admin/ssh_certificates' do
    let(:path) { '/admin/ssh_certificates' }
    let(:http_method) { :post }
    let(:title) { 'Engineering CA' }
    let(:key) { build(:rsa_key_4096).key }
    let(:params) { { title: title, key: key } }

    it_behaves_like 'an admin-only instance certificate endpoint'

    it 'creates a certificate and returns its unfiltered attributes', :aggregate_failures do
      expect { perform_request }.to change { InstanceSshCertificate.count }.by(1)

      expect(response).to have_gitlab_http_status(:created)
      certificate = InstanceSshCertificate.find(json_response['id'])
      expect(json_response).to match(
        'id' => certificate.id,
        'title' => title,
        'key' => key,
        'created_at' => certificate.created_at.as_json
      )
      expect(certificate.fingerprint).to eq(
        Gitlab::SSHPublicKey.new(key).fingerprint_sha256.delete_prefix('SHA256:')
      )
    end

    context 'when a required parameter is missing' do
      where(:missing_parameter) { [:title, :key] }

      with_them do
        let(:params) { super().except(missing_parameter) }

        it 'returns bad request without creating a certificate', :aggregate_failures do
          expect { perform_request }.not_to change { InstanceSshCertificate.count }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end

    context 'when the key is invalid' do
      where(:key) { ['', 'invalid', 'ssh-rsa AAAB3NzaC1yc2EAAAADAQABAAAAgQCxT+'] }

      with_them do
        it 'returns a key-oriented validation error', :aggregate_failures do
          expect { perform_request }.not_to change { InstanceSshCertificate.count }

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Validation failed: Invalid key')
        end
      end
    end

    context 'when the title is blank' do
      let(:title) { '' }

      it 'returns a validation error', :aggregate_failures do
        expect { perform_request }.not_to change { InstanceSshCertificate.count }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']).to include('Title')
      end
    end

    context 'when the title exceeds the length limit' do
      let(:title) { 'a' * 256 }

      it 'returns an API validation error', :aggregate_failures do
        expect { perform_request }.not_to change { InstanceSshCertificate.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to include('title must be less than 255 characters')
      end
    end

    context 'when the key exceeds the length limit' do
      let(:key) { "#{super()} #{'a' * 5000}" }

      it 'returns an API validation error', :aggregate_failures do
        expect { perform_request }.not_to change { InstanceSshCertificate.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to include('key must be less than 5000 characters')
      end
    end

    context 'when the CA already exists' do
      before do
        create(:instance_ssh_certificate, title: 'Existing CA', key: key)
      end

      it 'rejects the same key with a different title and comment', :aggregate_failures do
        params[:key] = "#{key.split.take(2).join(' ')} another@example.com"

        expect { perform_request }.not_to change { InstanceSshCertificate.count }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']).to include('This CA has already been configured.')
      end
    end

    context 'in FIPS mode', :fips_mode do
      it 'accepts a 4096-bit RSA key' do
        perform_request

        expect(response).to have_gitlab_http_status(:created)
      end

      context 'with a non-compliant key' do
        where(:key_factory) { [:rsa_key_2048, :dsa_key_2048] }

        with_them do
          let(:key) { build(key_factory).key }

          it 'returns a key validation error', :aggregate_failures do
            expect { perform_request }.not_to change { InstanceSshCertificate.count }

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(json_response['message']).to include('Key')
          end
        end
      end
    end

    it_behaves_like 'authorizing granular token permissions', :create_ssh_certificate,
      expected_success_status: :created do
      let(:user) { admin }
      let(:boundary_object) { :instance }
      let(:request) { post api(path, personal_access_token: pat), params: params }
    end
  end

  describe 'DELETE /admin/ssh_certificates/:id' do
    let_it_be(:certificate) { create(:instance_ssh_certificate, key: build(:rsa_key_4096).key) }
    let(:certificate_id) { certificate.id }
    let(:path) { "/admin/ssh_certificates/#{certificate_id}" }
    let(:http_method) { :delete }

    it_behaves_like 'an admin-only instance certificate endpoint'

    it 'deletes the certificate and returns no content', :aggregate_failures do
      expect { perform_request }.to change { InstanceSshCertificate.count }.by(-1)

      expect(response).to have_gitlab_http_status(:no_content)
      expect(response.body).to be_empty
      expect(InstanceSshCertificate.exists?(certificate_id)).to be(false)
    end

    context 'when the certificate does not exist' do
      let(:certificate_id) { non_existing_record_id }

      it 'returns not found without deleting certificates', :aggregate_failures do
        expect { perform_request }.not_to change { InstanceSshCertificate.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the certificate cannot be destroyed' do
      before do
        allow_next_found_instance_of(InstanceSshCertificate) do |record|
          allow(record).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)
        end
      end

      it 'returns an error without deleting certificates', :aggregate_failures do
        expect { perform_request }.not_to change { InstanceSshCertificate.count }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']).to eq('SSH Certificate could not be deleted')
      end
    end

    it_behaves_like 'authorizing granular token permissions', :delete_ssh_certificate,
      expected_success_status: :no_content do
      let(:user) { admin }
      let(:boundary_object) { :instance }
      let(:request) { delete api(path, personal_access_token: pat) }
    end
  end
end
