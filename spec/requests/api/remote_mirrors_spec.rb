# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::RemoteMirrors, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user) { |u| project.add_developer(u) } }
  let_it_be(:remote_mirror) { create(:remote_mirror, :host_keys, enabled: true, project: project) }

  let(:host_key) { 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf' }
  # rubocop:disable Layout/LineLength -- SSH key format requires long lines
  let(:rsa_key) { 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLIp+4ciR2YO9f9rpldc7InNQw/TBUtcNbJ2XR0rr15/5ytz7YM16xXG0Qjx576PNSmqs4gbTrvTuFZak+v1Jx/9deHRq/yqp9f+tv33+iaJGCQCX/+OVY7aWgV2R9YsS7XQ4mnv4XlOTEssib/rGAIT+ATd/GcdYSEOO+dh4O09/6O/jIMGSeP+NNetgn1nPCnLOjrXFZUnUtNDi6EEKeIlrliJjSb7Jr4f7gjvZnv4RskWHHFo8FgAAqt0gOMT6EmKrnypBe2vLGSAXbtkXr01q6/DNPH+n9VA1LTV6v1KN/W5CN5tQV11wRSKiM8g5OEbi86VjJRi2sOuYoXQU1' }
  # rubocop:enable Layout/LineLength

  describe 'GET /projects/:id/remote_mirrors' do
    let(:route) { "/projects/#{project.id}/remote_mirrors" }

    it 'requires `admin_remote_mirror` permission' do
      get api(route, developer)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'with sufficient permissions' do
      before do
        project.add_maintainer(user)
      end

      it 'returns a list of remote mirrors' do
        get api(route, user)

        expect(response).to have_gitlab_http_status(:success)
        expect(response).to match_response_schema('remote_mirrors')
      end

      it_behaves_like 'authorizing granular token permissions', :read_remote_mirror do
        let(:boundary_object) { project }
        let(:request) do
          get api(route, personal_access_token: pat)
        end
      end
    end
  end

  describe 'GET /projects/:id/remote_mirrors/:mirror_id' do
    let(:route) { "/projects/#{project.id}/remote_mirrors/#{mirror.id}" }
    let(:mirror) { remote_mirror }

    it 'requires `admin_remote_mirror` permission' do
      get api(route, developer)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'with sufficient permissions' do
      before do
        project.add_maintainer(user)
      end

      it 'returns a remote mirror' do
        get api(route, user)

        expect(response).to have_gitlab_http_status(:success)
        expect(response).to match_response_schema('remote_mirror')
        expect(json_response['host_keys']).to be_present
      end

      it_behaves_like 'authorizing granular token permissions', :read_remote_mirror do
        let(:boundary_object) { project }
        let(:request) do
          get api(route, personal_access_token: pat)
        end
      end

      context "when remote mirror doesn't have host_keys" do
        let(:mirror) { create(:remote_mirror, project: project) }

        it 'returns an empty host_keys array' do
          get api(route, user)

          expect(response).to have_gitlab_http_status(:success)
          expect(response).to match_response_schema('remote_mirror')
          expect(json_response['host_keys']).to be_empty
        end
      end
    end
  end

  describe 'POST /projects/:id/remote_mirrors/:mirror_id/sync' do
    let(:route) { "/projects/#{project.id}/remote_mirrors/#{mirror_id}/sync" }
    let(:mirror) { remote_mirror }
    let(:mirror_id) { mirror.id }

    context 'without enough permissions' do
      it 'requires `admin_remote_mirror` permission' do
        post api(route, developer)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with sufficient permissions' do
      before do
        project.add_maintainer(user)
      end

      it 'returns a successful response' do
        post api(route, user)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it_behaves_like 'authorizing granular token permissions', :sync_remote_mirror do
        let(:boundary_object) { project }
        let(:request) do
          post api(route, personal_access_token: pat)
        end
      end

      context 'when some error occurs' do
        before do
          mirror.update!(enabled: false)
        end

        it 'returns an error' do
          post api(route, user)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to match(/Cannot proceed with the push mirroring/)
        end
      end

      context 'when mirror ID is missing' do
        let(:mirror_id) { non_existing_record_id }

        it 'returns a not found error' do
          post api(route, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'POST /projects/:id/remote_mirrors' do
    let(:route) { "/projects/#{project.id}/remote_mirrors" }

    it 'requires `admin_remote_mirror` permission' do
      post api(route, developer)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'with sufficient permissions' do
      before do
        project.add_maintainer(user)
      end

      shared_examples 'creates a remote mirror' do
        it 'creates a remote mirror and returns response' do
          post api(route, user), params: params

          enabled = params.fetch(:enabled, false)
          auth_method = params.fetch(:auth_method, 'password')
          expect(response).to have_gitlab_http_status(:success)
          expect(response).to match_response_schema('remote_mirror')
          expect(json_response['enabled']).to eq(enabled)
          expect(json_response['auth_method']).to eq(auth_method)
        end
      end

      context 'creates a remote mirror' do
        context 'disabled by default' do
          let(:params) { { url: 'https://foo:bar@test.com' } }

          it_behaves_like 'creates a remote mirror'
        end

        context 'enabled' do
          let(:params) { { url: 'https://foo:bar@test.com', enabled: true } }

          it_behaves_like 'creates a remote mirror'
        end

        context 'auth method' do
          let(:params) { { url: 'https://foo:bar@test.com', enabled: true, auth_method: 'ssh_public_key' } }

          it_behaves_like 'creates a remote mirror'
        end
      end

      it 'returns error if url is invalid' do
        post api(route, user), params: {
          url: 'ftp://foo:bar@test.com'
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['url']).to match_array(
          ["is blocked: Only allowed schemes are http, https, ssh, git"]
        )
      end

      context 'with host_keys parameter' do
        let(:mirror_url) { 'ssh://git@example.com/foo/bar.git' }
        let(:request) { post api(route, user), params: { url: mirror_url, host_keys: host_keys } }
        let(:created_mirror) { RemoteMirror.find(json_response['id']) }

        context 'with a bare key' do
          let(:host_keys) { [host_key] }

          it 'creates a remote mirror with ssh_known_hosts prepending hostname' do
            request

            expect(response).to have_gitlab_http_status(:success)
            expect(response).to match_response_schema('remote_mirror')
            expect(created_mirror.ssh_known_hosts).to eq("example.com #{host_key}")
          end
        end

        context 'with a bare key and non-standard port URL' do
          let(:mirror_url) { 'ssh://git@example.com:2222/foo/bar.git' }
          let(:host_keys) { [host_key] }

          it 'creates a remote mirror with [host]:port format in ssh_known_hosts' do
            request

            expect(response).to have_gitlab_http_status(:success)
            expect(response).to match_response_schema('remote_mirror')
            expect(created_mirror.ssh_known_hosts).to eq("[example.com]:2222 #{host_key}")
          end
        end

        context 'with a full format key' do
          let(:full_key) { "mirror.example.org #{host_key}" }
          let(:host_keys) { [full_key] }

          it 'creates a remote mirror preserving the provided hostname' do
            request

            expect(response).to have_gitlab_http_status(:success)
            expect(created_mirror.ssh_known_hosts).to eq(full_key)
          end
        end

        context 'with multiple keys' do
          let(:host_keys) { [host_key, rsa_key] }

          it 'creates a remote mirror with all keys joined by newlines' do
            request

            expect(response).to have_gitlab_http_status(:success)
            expect(created_mirror.ssh_known_hosts).to eq("example.com #{host_key}\nexample.com #{rsa_key}")
          end
        end

        context 'with form-encoded key where + is decoded to space' do
          let(:host_keys) { [rsa_key.tr('+', ' ')] }

          it 'restores + characters and creates the mirror successfully' do
            request

            expect(response).to have_gitlab_http_status(:success)
            expect(response).to match_response_schema('remote_mirror')
            expect(created_mirror.ssh_known_hosts).to eq("example.com #{rsa_key}")
          end
        end

        context 'with invalid host_keys' do
          let(:host_keys) { ['invalid_key'] }

          it 'returns 400 with error message' do
            request

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to include('Invalid SSH host key')
          end
        end

        context 'with mix of valid and invalid host_keys' do
          let(:host_keys) { [host_key, 'invalid_key'] }

          it 'returns 400 and does not create a mirror' do
            expect { request }.not_to change { project.remote_mirrors.count }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to include('Invalid SSH host key')
          end
        end

        context 'with too many host_keys' do
          let(:host_keys) { Array.new(11, host_key) }

          it 'returns 400 with error message' do
            request

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to include('too many host keys')
          end
        end
      end

      context 'when auth method is invalid' do
        let(:params) { { url: 'https://foo:bar@test.com', enabled: true, auth_method: 'invalid' } }

        it 'returns an error' do
          post api(route, user), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq('auth_method does not have a valid value')
        end
      end

      context 'when only_protected_branches is not set' do
        let(:params) { { url: 'https://foo:bar@test.com', enabled: true, only_protected_branches: nil } }

        it 'returns an error' do
          post api(route, user), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['only_protected_branches']).to match_array(["can't be blank"])
        end
      end

      it_behaves_like 'authorizing granular token permissions', :create_remote_mirror do
        let(:boundary_object) { project }
        let(:request) do
          post api(route, personal_access_token: pat), params: { url: 'https://foo:bar@test.com' }
        end
      end
    end
  end

  describe 'PUT /projects/:id/remote_mirrors/:mirror_id' do
    let(:route) { "/projects/#{project.id}/remote_mirrors/#{mirror.id}" }
    let(:mirror) { remote_mirror }

    it 'requires `admin_remote_mirror` permission' do
      put api(route, developer)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'with sufficient permissions' do
      before do
        project.add_maintainer(user)
      end

      it 'updates a remote mirror' do
        put api(route, user), params: {
          enabled: '0',
          only_protected_branches: 'true',
          keep_divergent_refs: 'true'
        }

        expect(response).to have_gitlab_http_status(:success)
        expect(json_response['enabled']).to eq(false)
        expect(json_response['only_protected_branches']).to eq(true)
        expect(json_response['keep_divergent_refs']).to eq(true)
      end

      context 'when auth method is invalid' do
        let(:params) { { enabled: true, auth_method: 'invalid' } }

        it 'returns an error' do
          put api(route, user), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['auth_method']).to match_array(['is not included in the list'])
        end
      end

      context 'when only_protected_branches is not set' do
        let(:params) { { enabled: true, only_protected_branches: nil } }

        it 'returns an error' do
          put api(route, user), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['only_protected_branches']).to match_array(["can't be blank"])
        end
      end

      it_behaves_like 'authorizing granular token permissions', :update_remote_mirror do
        let(:boundary_object) { project }
        let(:request) do
          put api(route, personal_access_token: pat), params: { enabled: true }
        end
      end

      context 'with host_keys parameter' do
        let(:mirror) { create(:remote_mirror, :host_keys, project: project, url: 'ssh://git@example.com/foo/bar.git') }
        let(:request) { put api(route, user), params: { host_keys: host_keys } }

        context 'with a bare key' do
          let(:host_keys) { [host_key] }

          it 'updates ssh_known_hosts prepending hostname from mirror URL' do
            request

            expect(response).to have_gitlab_http_status(:success)
            expect(mirror.reload.ssh_known_hosts).to eq("example.com #{host_key}")
          end
        end

        context 'with a bare key and non-standard port URL' do
          let(:mirror) do
            create(:remote_mirror, :host_keys, project: project, url: 'ssh://git@example.com:2222/foo/bar.git')
          end

          let(:host_keys) { [host_key] }

          it 'updates ssh_known_hosts with [host]:port format' do
            request

            expect(response).to have_gitlab_http_status(:success)
            expect(mirror.reload.ssh_known_hosts).to eq("[example.com]:2222 #{host_key}")
          end
        end

        context 'with a full format key' do
          let(:full_key) { "mirror.example.org #{host_key}" }
          let(:host_keys) { [full_key] }

          it 'updates ssh_known_hosts preserving the provided hostname' do
            request

            expect(response).to have_gitlab_http_status(:success)
            expect(mirror.reload.ssh_known_hosts).to eq(full_key)
          end
        end

        context 'with multiple keys' do
          let(:host_keys) { [host_key, rsa_key] }

          it 'updates ssh_known_hosts with all keys joined by newlines' do
            request

            expect(response).to have_gitlab_http_status(:success)
            expect(mirror.reload.ssh_known_hosts).to eq("example.com #{host_key}\nexample.com #{rsa_key}")
          end
        end

        context 'with an empty array' do
          let(:host_keys) { [] }

          it 'clears ssh_known_hosts' do
            expect(mirror.ssh_known_hosts).to be_present

            request

            expect(response).to have_gitlab_http_status(:success)
            expect(mirror.reload.ssh_known_hosts).to be_nil
          end
        end

        context 'when host_keys is not provided' do
          it 'does not modify ssh_known_hosts' do
            original_known_hosts = mirror.ssh_known_hosts
            expect(original_known_hosts).to be_present

            put api(route, user), params: { enabled: true }

            expect(response).to have_gitlab_http_status(:success)
            expect(mirror.reload.ssh_known_hosts).to eq(original_known_hosts)
          end
        end

        context 'with invalid host_keys' do
          let(:host_keys) { ['invalid_key'] }

          it 'returns 400 with error message' do
            original_known_hosts = mirror.ssh_known_hosts

            request

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to include('Invalid SSH host key')
            expect(mirror.reload.ssh_known_hosts).to eq(original_known_hosts)
          end
        end
      end
    end
  end

  describe 'DELETE /projects/:id/remote_mirrors/:mirror_id' do
    let(:route) { ->(id) { "/projects/#{project.id}/remote_mirrors/#{id}" } }
    let(:mirror) { remote_mirror }

    it 'requires `admin_remote_mirror` permission' do
      expect { delete api(route[mirror.id], developer) }.not_to change { project.remote_mirrors.count }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'when the user is a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'returns 404 for non existing id' do
        delete api(route[non_existing_record_id], user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns bad request if the destroy service fails' do
        expect_next_instance_of(RemoteMirrors::DestroyService) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.error(message: 'error'))
        end

        expect { delete api(route[mirror.id], user) }.not_to change { project.remote_mirrors.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'message' => 'error' })
      end

      it 'deletes a remote mirror' do
        expect { delete api(route[mirror.id], user) }.to change { project.remote_mirrors.count }.from(1).to(0)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it_behaves_like 'authorizing granular token permissions', :delete_remote_mirror do
        let(:boundary_object) { project }
        let(:request) do
          delete api(route[mirror.id], personal_access_token: pat)
        end
      end
    end
  end

  describe 'GET /projects/:id/remote_mirrors/:mirror_id/public_key' do
    let(:route) { "/projects/#{project.id}/remote_mirrors/#{mirror.id}/public_key" }
    let(:mirror) { remote_mirror }

    it 'requires `admin_remote_mirror` permission' do
      get api(route, developer)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'when auth_method is not ssh_public_key' do
      it 'returns 404 Not Found' do
        project.add_maintainer(user)

        get api(route, user)

        expect(mirror.auth_method).not_to eq('ssh_public_key')
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when auth_method is ssh_public_key' do
      before do
        project.add_maintainer(user)
      end

      let(:mirror) do
        project.remote_mirrors.create!(url: 'ssh://foo.com', enabled: true, auth_method: 'ssh_public_key')
      end

      it 'returns the remote mirror public key' do
        get api(route, user)

        expect(mirror.auth_method).to eq('ssh_public_key')
        expect(response).to have_gitlab_http_status(:success)
        expect(json_response['public_key']).to eq(mirror.ssh_public_key)
      end

      it_behaves_like 'authorizing granular token permissions', :read_remote_mirror_public_key do
        let(:boundary_object) { project }

        let(:request) do
          get api(route, personal_access_token: pat)
        end
      end
    end
  end
end
