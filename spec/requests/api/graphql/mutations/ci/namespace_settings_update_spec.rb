# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'NamespaceSettingsUpdate', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group, :public) }

  let(:variables) do
    {
      full_path: namespace.full_path,
      pipeline_variables_default_role: 'DEVELOPER'
    }
  end

  let(:mutation) { graphql_mutation(:namespace_settings_update, variables, 'errors') }

  subject(:request) { post_graphql_mutation(mutation, current_user: user) }

  context 'when unauthorized' do
    let_it_be(:user) { create(:user) }

    shared_examples 'unauthorized' do
      it 'returns an error' do
        request

        expect(graphql_errors).not_to be_empty
      end
    end

    context 'when not a namespace member' do
      it_behaves_like 'unauthorized'
    end

    context 'when a non-maintainer namespace member' do
      before_all do
        namespace.add_developer(user)
      end

      it_behaves_like 'unauthorized'
    end
  end

  shared_examples 'authorized maintainer' do
    it 'updates pipeline_variables_default_role' do
      request

      expect(namespace.reload.namespace_settings.pipeline_variables_default_role).to eq('developer')
      expect(graphql_errors).to be_nil
    end
  end

  context 'when authorized' do
    let_it_be(:user) { create(:user) }

    context 'with an owner role' do
      before_all do
        namespace.add_owner(user)
      end

      it_behaves_like 'authorized maintainer'

      context 'when update is unsuccessful' do
        let(:update_service) { instance_double(::Ci::NamespaceSettings::UpdateService) }

        before do
          allow(::Ci::NamespaceSettings::UpdateService).to receive(:new) { update_service }
          allow(update_service)
          .to receive(:execute)
          .and_return ServiceResponse.error(message: ['Not allowed to update'])
        end

        it 'returns an error' do
          request

          expect(graphql_mutation_response(:namespace_settings_update)['errors']).not_to be_empty
        end
      end
    end

    context 'with a maitainer role' do
      before_all do
        namespace.add_maintainer(user)
      end

      it_behaves_like 'authorized maintainer'
    end

    it 'does not update pipeline_variables_default_role if not specified' do
      variables.except!(:pipeline_variables_default_role)

      request

      expect(namespace.reload.namespace_settings.pipeline_variables_default_role).to eq('no_one_allowed')
    end

    context 'when bad arguments are provided' do
      let(:variables) { { full_path: '' } }

      it 'returns the errors' do
        request

        expect(graphql_errors).to be_present
      end
    end
  end
end
