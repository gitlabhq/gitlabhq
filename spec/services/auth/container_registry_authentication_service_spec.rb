# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Auth::ContainerRegistryAuthenticationService, feature_category: :container_registry do
  include AdminModeHelper

  it_behaves_like 'a container registry auth service'

  describe '#execute with a granular (fine-grained) personal access token' do
    let_it_be(:rsa_key) { OpenSSL::PKey::RSA.generate(3072) }
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :private) }
    let_it_be(:other_project) { create(:project, :private) }

    # Granular PATs carry no legacy authentication abilities; access is
    # authorized per-boundary via the token instead.
    let(:authentication_abilities) { [] }
    let(:requested_project) { project }
    let(:action) { 'pull' }
    let(:permissions) { [:read_container_repository] }

    let(:granular_pat) do
      create(:granular_pat,
        user: user,
        boundary: ::Authz::Boundary.for(project),
        permissions: permissions)
    end

    let(:current_params) { { scopes: ["repository:#{requested_project.full_path}:#{action}"] } }
    let(:payload) { JWT.decode(result[:token], rsa_key, true, { algorithm: 'RS256' }).first }

    subject(:result) do
      described_class.new(requested_project, user, current_params)
        .execute(authentication_abilities: authentication_abilities, personal_access_token: granular_pat)
    end

    before_all do
      project.add_developer(user)
      other_project.add_developer(user)
    end

    before do
      stub_container_registry_config(enabled: true, issuer: 'rspec', key: nil)
      allow_next_instance_of(JSONWebToken::RSAToken) do |instance|
        allow(instance).to receive(:key).and_return(rsa_key)
      end
    end

    context 'when pulling from a project within the token boundary' do
      it 'authorizes the pull' do
        expect(payload['access']).to contain_exactly(
          a_hash_including('type' => 'repository', 'name' => project.full_path, 'actions' => ['pull'])
        )
      end
    end

    context 'when pulling from a project outside the token boundary' do
      let(:requested_project) { other_project }

      it 'does not authorize the pull even though the user can read the project' do
        expect(payload['access']).to be_empty
      end
    end

    context 'when the token holds an unrelated permission' do
      # A granular PAT can complete `docker login` (the registry ability gate is
      # open for granular tokens), but that must not translate into actual access
      # when the token does not hold the matching container repository permission.
      let(:permissions) { [:read_code] }

      it 'does not authorize the pull' do
        expect(payload['access']).to be_empty
      end
    end

    context 'when pushing with a read-scoped token' do
      let(:action) { 'push' }

      it 'does not authorize the push (no granular push permission exists)' do
        expect(payload['access']).to be_empty
      end
    end

    context 'when deleting with a Container Repository: Delete token' do
      let(:action) { 'delete' }
      let(:permissions) { [:delete_container_repository] }

      before_all do
        # Deleting images requires maintainer access in addition to the granular permission.
        project.add_maintainer(user)
        other_project.add_maintainer(user)
      end

      it 'authorizes the delete within the boundary' do
        expect(payload['access']).to contain_exactly(
          a_hash_including('type' => 'repository', 'name' => project.full_path, 'actions' => ['delete'])
        )
      end

      context 'when the project is outside the token boundary' do
        let(:requested_project) { other_project }

        it 'does not authorize the delete' do
          expect(payload['access']).to be_empty
        end
      end

      context 'when requesting the wildcard (admin) action' do
        let(:action) { '*' }

        # `*` implies all actions, including push. A granular PAT has no push
        # permission, so it must never be granted `*`, even with a Delete
        # permission and maintainer access on the project.
        it 'does not authorize the wildcard action within the boundary' do
          expect(payload['access']).to be_empty
        end
      end
    end
  end

  describe '#execute with a legacy personal access token in an enforced namespace' do
    let_it_be(:rsa_key) { OpenSSL::PKey::RSA.generate(3072) }
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :private, group: group) }

    let(:authentication_abilities) { [:read_container_image] }
    let(:current_params) { { scopes: ["repository:#{project.full_path}:pull"] } }
    let(:payload) { JWT.decode(result[:token], rsa_key, true, { algorithm: 'RS256' }).first }

    # A legacy PAT scoped only to `read_code` would be authorized for a registry
    # pull under the legacy ability gate, but in an enforced namespace it must
    # also satisfy the granular boundary check, which it does not.
    let(:legacy_pat) { create(:personal_access_token, user: user, scopes: [:read_registry]) }

    subject(:result) do
      described_class.new(project, user, current_params)
        .execute(authentication_abilities: authentication_abilities, personal_access_token: legacy_pat)
    end

    before_all do
      project.add_developer(user)
    end

    before do
      stub_container_registry_config(enabled: true, issuer: 'rspec', key: nil)
      allow_next_instance_of(JSONWebToken::RSAToken) do |instance|
        allow(instance).to receive(:key).and_return(rsa_key)
      end

      stub_feature_flags(granular_personal_access_tokens: true)
      ::NamespaceSetting.find_by!(namespace_id: group.id).update!(
        enforce_granular_tokens: true,
        granular_tokens_enforced_after: Date.current
      )
    end

    it 'denies the pull because the legacy token holds no granular permission' do
      expect(payload['access']).to be_empty
    end
  end

  describe '#execute with a legacy personal access token in a non-enforced namespace' do
    let_it_be(:rsa_key) { OpenSSL::PKey::RSA.generate(3072) }
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :private, group: group) }

    let(:authentication_abilities) { [:read_container_image] }
    let(:current_params) { { scopes: ["repository:#{project.full_path}:pull"] } }
    let(:payload) { JWT.decode(result[:token], rsa_key, true, { algorithm: 'RS256' }).first }

    let(:legacy_pat) { create(:personal_access_token, user: user, scopes: [:read_registry]) }

    subject(:result) do
      described_class.new(project, user, current_params)
        .execute(authentication_abilities: authentication_abilities, personal_access_token: legacy_pat)
    end

    before_all do
      project.add_developer(user)
    end

    before do
      stub_container_registry_config(enabled: true, issuer: 'rspec', key: nil)
      allow_next_instance_of(JSONWebToken::RSAToken) do |instance|
        allow(instance).to receive(:key).and_return(rsa_key)
      end

      # Granular tokens are enabled globally, but the namespace does not enforce
      # them, so a legacy PAT must keep pulling as before (no regression).
      stub_feature_flags(granular_personal_access_tokens: true)
    end

    it 'authorizes the pull because granular tokens are not enforced' do
      expect(payload['access']).to contain_exactly(
        a_hash_including('type' => 'repository', 'name' => project.full_path, 'actions' => ['pull'])
      )
    end
  end
end
