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

    shared_examples 'an unmodified token' do
      it_behaves_like 'a valid token'
      it { expect(payload['access']).not_to include(have_key('migration_eligible')) }
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

      it_behaves_like 'an unmodified token'
    end

    context 'with push action' do
      let(:current_params) do
        { scopes: ["repository:#{project.full_path}:push"] }
      end

      it_behaves_like 'a modified token'
    end

    context 'with multiple actions including push' do
      let(:current_params) do
        { scopes: ["repository:#{project.full_path}:pull,push,delete"] }
      end

      it_behaves_like 'a modified token'
    end

    context 'with multiple actions excluding push' do
      let(:current_params) do
        { scopes: ["repository:#{project.full_path}:pull,delete"] }
      end

      it_behaves_like 'an unmodified token'
    end
  end
end
