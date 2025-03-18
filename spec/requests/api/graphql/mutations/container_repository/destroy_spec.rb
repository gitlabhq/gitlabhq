# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying a container repository', feature_category: :container_registry do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be_with_reload(:container_repository) { create(:container_repository) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:project) { container_repository.project }
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

  let(:tags) { %w[a b c] }

  before do
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(tags: tags)
  end

  shared_examples 'destroying the container repository' do
    it 'marks the container repository as delete_scheduled' do
      expect(::Packages::CreateEventService)
          .to receive(:new).with(nil, current_user, event_name: :delete_repository, scope: :container).and_call_original

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

  shared_examples 'returning an error' do
    it 'returns an error' do
      subject

      expect_graphql_errors_to_include(
        'The resource that you are attempting to access does not exist ' \
          'or you don\'t have permission to perform this action'
      )
    end
  end

  describe 'post graphql mutation' do
    subject { post_graphql_mutation(mutation, current_user:) }

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
          project.send("add_#{user_role}", current_user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'with invalid id' do
      let(:params) { { id: 'gid://gitlab/ContainerRepository/5555' } }

      it_behaves_like 'denying the mutation request'
    end

    context 'when the project has tag protection rules' do
      before_all do
        create(
          :container_registry_protection_tag_rule,
          project: project,
          minimum_access_level_for_delete: :owner
        )
      end

      where(:user_role, :shared_examples_name) do
        :owner      | 'destroying the container repository'
        :maintainer | 'returning an error'
        :developer  | 'returning an error'
      end

      with_them do
        before do
          project.send("add_#{user_role}", current_user)
        end

        it_behaves_like params[:shared_examples_name]
      end

      context 'when the container repository does not have tags' do
        let(:tags) { [] }

        %i[owner maintainer developer].each do |user_role|
          context "with the role of #{user_role}" do
            before do
              project.send("add_#{user_role}", current_user)
            end

            it_behaves_like 'destroying the container repository'
          end
        end
      end

      context 'when the current user is an admin', :enable_admin_mode do
        let(:current_user) { create(:admin) }

        it_behaves_like 'destroying the container repository'
      end

      context 'when the feature container_registry_protected_tags is disabled' do
        %i[owner maintainer developer].each do |user_role|
          context "with the role of #{user_role}" do
            before do
              stub_feature_flags(container_registry_protected_tags: false)
              project.send("add_#{user_role}", current_user)
            end

            it_behaves_like 'destroying the container repository'
          end
        end
      end
    end
  end
end
