# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Auth::ContainerRegistryAuthenticationService do
  include AdminModeHelper

  it_behaves_like 'a container registry auth service'

  context 'when in migration mode' do
    include_context 'container registry auth service context'

    let_it_be(:current_user) { create(:user) }
    let_it_be(:project) { create(:project) }

    before do
      project.add_developer(current_user)
    end

    shared_examples 'a modified token with migration eligibility' do |eligible|
      it_behaves_like 'a valid token'
      it { expect(payload['access']).to include(include('migration_eligible' => eligible)) }
    end

    shared_examples 'a modified token' do
      context 'with a non eligible root ancestor and project' do
        before do
          stub_feature_flags(container_registry_migration_phase1_deny: project.root_ancestor)
          stub_feature_flags(container_registry_migration_phase1_allow: false)
        end

        it_behaves_like 'a modified token with migration eligibility', false
      end

      context 'with a non eligible root ancestor and eligible project' do
        before do
          stub_feature_flags(container_registry_migration_phase1_deny: false)
          stub_feature_flags(container_registry_migration_phase1_deny: project.root_ancestor)
          stub_feature_flags(container_registry_migration_phase1_allow: project)
        end

        it_behaves_like 'a modified token with migration eligibility', false
      end

      context 'with an eligible root ancestor and non eligible project' do
        before do
          stub_feature_flags(container_registry_migration_phase1_deny: false)
          stub_feature_flags(container_registry_migration_phase1_allow: false)
        end

        it_behaves_like 'a modified token with migration eligibility', false
      end

      context 'with an eligible root ancestor and project' do
        before do
          stub_feature_flags(container_registry_migration_phase1_deny: false)
          stub_feature_flags(container_registry_migration_phase1_allow: project)
        end

        it_behaves_like 'a modified token with migration eligibility', true
      end
    end

    context 'with pull action' do
      let(:current_params) do
        { scopes: ["repository:#{project.full_path}:pull"] }
      end

      it_behaves_like 'a modified token'
    end

    context 'with push action' do
      let(:current_params) do
        { scopes: ["repository:#{project.full_path}:push"] }
      end

      it_behaves_like 'a modified token'
    end

    context 'with multiple actions' do
      let(:current_params) do
        { scopes: ["repository:#{project.full_path}:pull,push,delete"] }
      end

      it_behaves_like 'a modified token'
    end

    describe '#access_token' do
      let(:token) { described_class.access_token(%w[push], [project.full_path]) }

      subject { { token: token } }

      it_behaves_like 'a modified token'
    end

    context 'with a project with a path with trailing underscore' do
      let(:bad_project) { create(:project) }

      before do
        bad_project.update!(path: bad_project.path + '_')
        bad_project.add_developer(current_user)
      end

      describe '#full_access_token' do
        let(:token) { described_class.full_access_token(bad_project.full_path) }
        let(:access) do
          [{ 'type' => 'repository',
             'name' => bad_project.full_path,
             'actions' => ['*'],
             'migration_eligible' => false }]
        end

        subject { { token: token } }

        it 'logs an exception and returns a valid access token' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

          expect(token).to be_present
          expect(payload).to be_a(Hash)
          expect(payload).to include('access' => access)
        end
      end
    end
  end

  context 'when not in migration mode' do
    include_context 'container registry auth service context'

    let_it_be(:project) { create(:project) }

    before do
      stub_feature_flags(container_registry_migration_phase1: false)
    end

    shared_examples 'an unmodified token' do
      it_behaves_like 'a valid token'
      it { expect(payload['access']).not_to include(have_key('migration_eligible')) }
    end

    describe '#access_token' do
      let(:token) { described_class.access_token(%w[push], [project.full_path]) }

      subject { { token: token } }

      it_behaves_like 'an unmodified token'
    end
  end

  context 'CDN redirection' do
    include_context 'container registry auth service context'

    let_it_be(:current_user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:current_params) { { scopes: ["repository:#{project.full_path}:pull"] } }

    before do
      project.add_developer(current_user)
    end

    it_behaves_like 'a valid token'
    it { expect(payload['access']).to include(include('cdn_redirect' => true)) }

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(container_registry_cdn_redirect: false)
      end

      it_behaves_like 'a valid token'
      it { expect(payload['access']).not_to include(have_key('cdn_redirect')) }
    end
  end
end
