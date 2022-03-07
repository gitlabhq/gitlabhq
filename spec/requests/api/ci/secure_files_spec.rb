# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::SecureFiles do
  before do
    stub_ci_secure_file_object_storage
    stub_feature_flags(ci_secure_files: true)
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:project) { create(:project, creator_id: user.id) }
  let_it_be(:maintainer) { create(:project_member, :maintainer, user: user, project: project) }
  let_it_be(:developer) { create(:project_member, :developer, user: user2, project: project) }
  let_it_be(:secure_file) { create(:ci_secure_file, project: project) }

  describe 'GET /projects/:id/secure_files' do
    context 'feature flag' do
      it 'returns a 503 when the feature flag is disabled' do
        stub_feature_flags(ci_secure_files: false)

        get api("/projects/#{project.id}/secure_files", user)

        expect(response).to have_gitlab_http_status(:service_unavailable)
      end

      it 'returns a 200 when the feature flag is enabled' do
        get api("/projects/#{project.id}/secure_files", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a(Array)
      end
    end

    context 'authorized user with proper permissions' do
      it 'returns project secure files' do
        get api("/projects/#{project.id}/secure_files", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a(Array)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not return project secure files' do
        get api("/projects/#{project.id}/secure_files", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not return project secure files' do
        get api("/projects/#{project.id}/secure_files")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /projects/:id/secure_files/:secure_file_id' do
    context 'authorized user with proper permissions' do
      it 'returns project secure file details' do
        get api("/projects/#{project.id}/secure_files/#{secure_file.id}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(secure_file.name)
        expect(json_response['permissions']).to eq(secure_file.permissions)
      end

      it 'responds with 404 Not Found if requesting non-existing secure file' do
        get api("/projects/#{project.id}/secure_files/99999", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not return project secure file details' do
        get api("/projects/#{project.id}/secure_files/#{secure_file.id}", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not return project secure file details' do
        get api("/projects/#{project.id}/secure_files/#{secure_file.id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /projects/:id/secure_files/:secure_file_id/download' do
    context 'authorized user with proper permissions' do
      it 'returns a secure file' do
        sample_file = fixture_file('ci_secure_files/upload-keystore.jks')
        secure_file.file = CarrierWaveStringFile.new(sample_file)
        secure_file.save!

        get api("/projects/#{project.id}/secure_files/#{secure_file.id}/download", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(Base64.encode64(response.body)).to eq(Base64.encode64(sample_file))
      end

      it 'responds with 404 Not Found if requesting non-existing secure file' do
        get api("/projects/#{project.id}/secure_files/99999/download", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not return project secure file details' do
        get api("/projects/#{project.id}/secure_files/#{secure_file.id}/download", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not return project secure file details' do
        get api("/projects/#{project.id}/secure_files/#{secure_file.id}/download")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /projects/:id/secure_files' do
    context 'authorized user with proper permissions' do
      it 'creates a secure file' do
        params = {
          file: fixture_file_upload('spec/fixtures/ci_secure_files/upload-keystore.jks'),
          name: 'upload-keystore.jks',
          permissions: 'execute'
        }

        expect do
          post api("/projects/#{project.id}/secure_files", user), params: params
        end.to change {project.secure_files.count}.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq('upload-keystore.jks')
        expect(json_response['permissions']).to eq('execute')
        expect(json_response['checksum']).to eq(secure_file.checksum)
        expect(json_response['checksum_algorithm']).to eq('sha256')

        secure_file = Ci::SecureFile.find(json_response['id'])
        expect(secure_file.checksum).to eq(
          Digest::SHA256.hexdigest(fixture_file('ci_secure_files/upload-keystore.jks'))
        )
        expect(json_response['id']).to eq(secure_file.id)
        expect(Time.parse(json_response['created_at'])).to be_like_time(secure_file.created_at)
      end

      it 'creates a secure file with read_only permissions by default' do
        params = {
          file: fixture_file_upload('spec/fixtures/ci_secure_files/upload-keystore.jks'),
          name: 'upload-keystore.jks'
        }

        expect do
          post api("/projects/#{project.id}/secure_files", user), params: params
        end.to change {project.secure_files.count}.by(1)

        expect(json_response['permissions']).to eq('read_only')
      end

      it 'uploads and downloads a secure file' do
        post_params = {
          file: fixture_file_upload('spec/fixtures/ci_secure_files/upload-keystore.jks'),
          name: 'upload-keystore.jks',
          permissions: 'read_write'
        }

        post api("/projects/#{project.id}/secure_files", user), params: post_params

        secure_file_id = json_response['id']

        get api("/projects/#{project.id}/secure_files/#{secure_file_id}/download", user)

        expect(Base64.encode64(response.body)).to eq(Base64.encode64(fixture_file_upload('spec/fixtures/ci_secure_files/upload-keystore.jks').read))
      end

      it 'returns an error when the file checksum fails to validate' do
        secure_file.update!(checksum: 'foo')

        get api("/projects/#{project.id}/secure_files/#{secure_file.id}/download", user)

        expect(response.code).to eq("500")
      end

      it 'returns an error when no file is uploaded' do
        post_params = {
          name: 'upload-keystore.jks'
        }

        post api("/projects/#{project.id}/secure_files", user), params: post_params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('file is missing')
      end

      it 'returns an error when the file name is missing' do
        post_params = {
          file: fixture_file_upload('spec/fixtures/ci_secure_files/upload-keystore.jks')
        }

        post api("/projects/#{project.id}/secure_files", user), params: post_params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('name is missing')
      end

      it 'returns an error when an unexpected permission is supplied' do
        post_params = {
          file: fixture_file_upload('spec/fixtures/ci_secure_files/upload-keystore.jks'),
          name: 'upload-keystore.jks',
          permissions: 'foo'
        }

        post api("/projects/#{project.id}/secure_files", user), params: post_params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('permissions does not have a valid value')
      end

      it 'returns an error when an unexpected validation failure happens' do
        allow_next_instance_of(Ci::SecureFile) do |instance|
          allow(instance).to receive(:valid?).and_return(false)
          allow(instance).to receive_message_chain(:errors, :any?).and_return(true)
          allow(instance).to receive_message_chain(:errors, :messages).and_return(['Error 1', 'Error 2'])
        end

        post_params = {
          file: fixture_file_upload('spec/fixtures/ci_secure_files/upload-keystore.jks'),
          name: 'upload-keystore.jks'
        }

        post api("/projects/#{project.id}/secure_files", user), params: post_params

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns a 413 error when the file size is too large' do
        allow_next_instance_of(Ci::SecureFile) do |instance|
          allow(instance).to receive_message_chain(:file, :size).and_return(6.megabytes.to_i)
        end

        post_params = {
          file: fixture_file_upload('spec/fixtures/ci_secure_files/upload-keystore.jks'),
          name: 'upload-keystore.jks'
        }

        post api("/projects/#{project.id}/secure_files", user), params: post_params

        expect(response).to have_gitlab_http_status(:payload_too_large)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not create a secure file' do
        post api("/projects/#{project.id}/secure_files", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not create a secure file' do
        post api("/projects/#{project.id}/secure_files")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /projects/:id/secure_files/:secure_file_id' do
    context 'authorized user with proper permissions' do
      it 'deletes the secure file' do
        expect do
          delete api("/projects/#{project.id}/secure_files/#{secure_file.id}", user)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change {project.secure_files.count}.by(-1)
      end

      it 'responds with 404 Not Found if requesting non-existing secure_file' do
        delete api("/projects/#{project.id}/secure_files/99999", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not delete the secure_file' do
        delete api("/projects/#{project.id}/secure_files/#{secure_file.id}", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not delete the secure_file' do
        delete api("/projects/#{project.id}/secure_files/#{secure_file.id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
