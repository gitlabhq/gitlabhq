# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying a container repository', feature_category: :container_registry do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be_with_reload(:container_repository) { create(:container_repository) }
  let_it_be(:user) { create(:user) }

  let(:project) { container_repository.project }
  let(:id) { container_repository.to_global_id.to_s }

  let(:query) do
    <<~GQL
      containerRepository {
        #{all_graphql_fields_for('ContainerRepository')}
      }
      errors
    GQL
  end

  let(:params) { { id: id } }
  let(:mutation) { graphql_mutation(:destroy_container_repository, params, query) }
  let(:mutation_response) { graphql_mutation_response(:destroyContainerRepository) }
  let(:container_repository_mutation_response) { mutation_response['containerRepository'] }

  before do
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(tags: %w[a b c])
  end

  shared_examples 'destroying the container repository' do
    it 'marks the container repository as delete_scheduled' do
      expect(::Packages::CreateEventService)
          .to receive(:new).with(nil, user, event_name: :delete_repository, scope: :container).and_call_original

      subject

      expect(container_repository_mutation_response).to match_schema('graphql/container_repository')
      expect(container_repository_mutation_response['status']).to eq('DELETE_SCHEDULED')
    end

    it_behaves_like 'returning response status', :success
  end

  shared_examples 'denying the mutation request' do
    it 'does not destroy the container repository' do
      subject

      expect(mutation_response).to be_nil
    end

    it_behaves_like 'returning response status', :success
  end

  describe 'post graphql mutation' do
    subject { post_graphql_mutation(mutation, current_user: user) }

    context 'with valid id' do
      where(:user_role, :shared_examples_name) do
        :maintainer | 'destroying the container repository'
        :developer  | 'destroying the container repository'
        :reporter   | 'denying the mutation request'
        :guest      | 'denying the mutation request'
        :anonymous  | 'denying the mutation request'
      end

      with_them do
        before do
          project.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'with invalid id' do
      let(:params) { { id: 'gid://gitlab/ContainerRepository/5555' } }

      it_behaves_like 'denying the mutation request'
    end
  end
end
