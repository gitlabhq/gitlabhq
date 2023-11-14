# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying a container repository tags', feature_category: :container_registry do
  include_context 'container repository delete tags service shared context'
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let(:id) { repository.to_global_id.to_s }
  let(:tags) { %w[A C D E] }

  let(:query) do
    <<~GQL
      deletedTagNames
      errors
    GQL
  end

  let(:params) { { id: id, tag_names: tags } }
  let(:mutation) { graphql_mutation(:destroy_container_repository_tags, params, query) }
  let(:mutation_response) { graphql_mutation_response(:destroyContainerRepositoryTags) }
  let(:tag_names_response) { mutation_response['deletedTagNames'] }
  let(:errors_response) { mutation_response['errors'] }

  shared_examples 'destroying the container repository tags' do
    before do
      stub_delete_reference_requests(tags)
      expect_delete_tags(tags)
      allow_next_instance_of(ContainerRegistry::Client) do |client|
        allow(client).to receive(:supports_tag_delete?).and_return(true)
      end
    end

    it 'destroys the container repository tags' do
      expect(Projects::ContainerRepository::DeleteTagsService)
        .to receive(:new).and_call_original
      subject

      expect(tag_names_response).to eq(tags)
      expect(errors_response).to eq([])
    end

    it_behaves_like 'returning response status', :success
  end

  shared_examples 'denying the mutation request' do
    it 'does not destroy the container repository tags' do
      expect(Projects::ContainerRepository::DeleteTagsService)
        .not_to receive(:new)

      subject

      expect(mutation_response).to be_nil
    end

    it_behaves_like 'returning response status', :success
  end

  describe 'post graphql mutation' do
    subject { post_graphql_mutation(mutation, current_user: user) }

    context 'with valid id' do
      where(:user_role, :shared_examples_name) do
        :maintainer | 'destroying the container repository tags'
        :developer  | 'destroying the container repository tags'
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
      let(:id) { 'gid://gitlab/ContainerRepository/5555' }

      it_behaves_like 'denying the mutation request'
    end

    context 'with too many tags' do
      let(:tags) { Array.new(Mutations::ContainerRepositories::DestroyTags::LIMIT + 1, 'x') }

      it 'returns too many tags error' do
        subject

        explanation = graphql_errors.dig(0, 'message')
        expect(explanation).to eq(Mutations::ContainerRepositories::DestroyTags::TOO_MANY_TAGS_ERROR_MESSAGE)
      end
    end

    context 'with service error' do
      before do
        project.add_maintainer(user)
        allow_next_instance_of(Projects::ContainerRepository::DeleteTagsService) do |service|
          allow(service).to receive(:execute).and_return(message: 'could not delete tags', status: :error)
        end
      end

      it 'returns an error' do
        subject

        expect(tag_names_response).to eq([])
        expect(errors_response).to eq(['could not delete tags'])
      end

      it 'does not create a package event' do
        expect(::Packages::CreateEventService).not_to receive(:new)
        subject
      end
    end
  end
end
