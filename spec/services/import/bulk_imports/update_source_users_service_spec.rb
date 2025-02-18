# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::UpdateSourceUsersService, :clean_gitlab_redis_shared_state,
  feature_category: :importers do
  let_it_be(:portable) { create(:group) }
  let_it_be(:bulk_import) { create(:bulk_import, :with_configuration) }
  let_it_be(:source_hostname) { bulk_import.configuration.url }

  let_it_be(:import_source_user_1) do
    create(:import_source_user,
      namespace: portable,
      import_type: Import::SOURCE_DIRECT_TRANSFER,
      source_hostname: source_hostname,
      source_username: nil,
      source_name: nil
    )
  end

  let_it_be(:import_source_user_2) do
    create(:import_source_user,
      namespace: portable,
      import_type: Import::SOURCE_DIRECT_TRANSFER,
      source_hostname: source_hostname,
      source_username: nil,
      source_name: nil
    )
  end

  let_it_be(:import_source_user_3) do
    create(:import_source_user,
      namespace: portable,
      import_type: Import::SOURCE_DIRECT_TRANSFER,
      source_hostname: source_hostname,
      source_username: nil,
      source_name: nil
    )
  end

  let_it_be(:import_source_user_4) do
    create(:import_source_user,
      namespace: portable,
      import_type: Import::SOURCE_DIRECT_TRANSFER,
      source_hostname: source_hostname,
      source_username: 'johndoe',
      source_name: 'John Doe'
    )
  end

  let_it_be(:source_user_identifiers) do
    [
      "gid://gitlab/User/#{import_source_user_1.source_user_identifier}",
      "gid://gitlab/User/#{import_source_user_2.source_user_identifier}",
      "gid://gitlab/User/#{import_source_user_3.source_user_identifier}"
    ]
  end

  let_it_be(:node_0) { graphql_response_node(gid: source_user_identifiers[0]) }
  let_it_be(:node_1) { graphql_response_node(gid: source_user_identifiers[1]) }
  let_it_be(:node_2) { graphql_response_node(gid: source_user_identifiers[2]) }

  let(:service_args) do
    { bulk_import: bulk_import, namespace: portable }
  end

  def graphql_response_node(gid:, name: 'Name', username: 'username')
    {
      'id' => gid,
      'name' => name,
      'username' => username
    }
  end

  def graphql_response(nodes = [], has_next_page = false, next_page = '')
    instance_double(
      GraphQL::Client::Response,
      original_hash: {
        'data' => {
          'users' => {
            'pageInfo' => {
              'next_page' => next_page,
              'has_next_page' => has_next_page
            },
            'nodes' => nodes
          }
        }
      }
    )
  end

  describe '#execute' do
    subject(:service) { described_class.new(**service_args) }

    it 'updates missing source user details' do
      expect_next_instance_of(BulkImports::Clients::Graphql) do |client|
        expect(client).to receive(:parse).and_return('query')

        expect(client).to receive(:execute)
          .with('query', ids: source_user_identifiers, after: nil)
          .and_return(graphql_response([node_0]))
      end

      result = service.execute

      expect(import_source_user_1.reload.source_name).to be_present
      expect(import_source_user_1.source_username).to be_present
      expect(import_source_user_1.placeholder_user.reload.name).to be_present
      expect(import_source_user_1.placeholder_user.username).to be_present
      expect(import_source_user_4.reload.source_name).to eq('John Doe')
      expect(import_source_user_4.source_username).to eq('johndoe')
      expect(result).to be_success
    end

    context 'when bulk import configuration URL has a trailing slash' do
      it 'removes the trailing slash' do
        allow(bulk_import.configuration).to receive(:url).and_return("#{source_hostname}/")

        expect_next_instance_of(BulkImports::Clients::Graphql) do |client|
          expect(client).to receive(:parse).and_return('query')

          expect(client).to receive(:execute).with('query', ids: source_user_identifiers, after: nil)
            .and_return(graphql_response([node_0]))
        end

        expect(Import::SourceUser).to receive(:find_source_user).with(hash_including(source_hostname: source_hostname))

        service.execute
      end
    end
  end

  describe '#fetch_users_data' do
    subject(:fetch_users_data) { described_class.new(**service_args).send(:fetch_users_data) }

    it 'requests user details for the source users with missing details' do
      expect_next_instance_of(BulkImports::Clients::Graphql) do |client|
        expect(client).to receive(:parse).and_return('query')

        expect(client).to receive(:execute)
          .with('query', ids: match_array(source_user_identifiers), after: nil)
          .and_return(graphql_response([node_0, node_1, node_2]))
      end

      expect(fetch_users_data.each.to_a).to match_array([node_0, node_1, node_2])
    end

    context 'when response does not contain users' do
      it 'returns no data' do
        expect_next_instance_of(BulkImports::Clients::Graphql) do |client|
          expect(client).to receive(:parse).and_return('query')

          expect(client).to receive(:execute).and_return(graphql_response([]))
        end

        expect_next_instance_of(BulkImports::Logger) do |logger|
          expect(logger).to receive(:error).with(
            message: 'No users present in response',
            response: anything,
            user_ids: source_user_identifiers)
        end

        expect(fetch_users_data.each.to_a).to eq([])
      end
    end

    context 'when response is paginated' do
      it 'fetches the next pages' do
        expect_next_instance_of(BulkImports::Clients::Graphql) do |client|
          expect(client).to receive(:parse).and_return('query')

          expect(client).to receive(:execute)
            .with('query', ids: source_user_identifiers, after: nil)
            .and_return(graphql_response([node_0, node_1], true, 'next_page'))
            .ordered

          expect(client).to receive(:execute)
            .with('query', ids: source_user_identifiers, after: 'next_page')
            .and_return(graphql_response([node_2], false))
            .ordered
        end

        expect(fetch_users_data.each.to_a).to match_array([node_0, node_1, node_2])
      end
    end

    context 'when the number of source users is higher than the batch size' do
      it 'makes a request for each batch in descending order' do
        stub_const("#{described_class.name}::BATCH_SIZE", 2)

        expect_next_instance_of(BulkImports::Clients::Graphql) do |client|
          expect(client).to receive(:parse).and_return('query').ordered

          expect(client).to receive(:execute)
            .with('query', ids: [source_user_identifiers[1], source_user_identifiers[2]], after: nil)
            .and_return(graphql_response([node_1, node_2]))
            .ordered

          expect(client).to receive(:execute)
            .with('query', ids: [source_user_identifiers[0]], after: nil)
            .and_return(graphql_response([node_0]))
            .ordered
        end

        expect(fetch_users_data.each.to_a).to match_array([node_0, node_1, node_2])
      end
    end
  end

  describe '#update_source_user' do
    let(:data) do
      graphql_response_node(
        gid: "gid://gitlab/User/#{import_source_user_1.source_user_identifier}", name: 'John Doe', username: 'john_doe'
      )
    end

    subject(:update_source_user) { described_class.new(**service_args).send(:update_source_user, data) }

    it 'updates the source user attributes' do
      expect(Import::SourceUsers::UpdateService).to receive(:new).and_call_original

      expect_next_instance_of(::BulkImports::Logger) do |logger|
        expect(logger).to receive(:info).with(
          hash_including(
            message: 'Source user updated',
            source_user_id: import_source_user_1.id
          )
        )
      end

      update_source_user

      expect(import_source_user_1.reload).to have_attributes(
        source_name: 'John Doe',
        source_username: 'john_doe'
      )

      expect(import_source_user_1.placeholder_user.reload).to have_attributes(
        name: 'Placeholder John Doe',
        username: match(/\Ajohndoe_placeholder_[[:alnum:]]+\z/)
      )
    end

    context 'when gid can not be parsed' do
      let(:data) { graphql_response_node(gid: nil, name: 'John Doe', username: 'john_doe') }

      it 'does not update the source user attributes' do
        expect(Import::SourceUsers::UpdateService).not_to receive(:new)

        expect_next_instance_of(BulkImports::Logger) do |logger|
          expect(logger).to receive(:error).with(
            hash_including(message: 'Missing source user identifier')
          )
        end

        update_source_user
      end
    end

    context 'when name and username are nil' do
      let(:data) do
        graphql_response_node(gid: "gid://gitlab/User/#{import_source_user_1.source_user_identifier}",
          name: nil,
          username: nil
        )
      end

      it 'does not update the source user attributes' do
        expect(Import::SourceUsers::UpdateService).not_to receive(:new)

        expect_next_instance_of(BulkImports::Logger) do |logger|
          expect(logger).to receive(:error).with(
            hash_including(message: 'Missing source user information')
          )
        end

        update_source_user
      end
    end

    context 'when source user fails to be updated' do
      it 'logs the error' do
        allow_next_instance_of(Import::SourceUsers::UpdateService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'Error!'))
        end

        expect_next_instance_of(::BulkImports::Logger) do |logger|
          expect(logger).to receive(:error).with(
            hash_including(
              message: 'Failed to update source user',
              error: 'Error!',
              bulk_import_id: bulk_import.id,
              importer: Import::SOURCE_DIRECT_TRANSFER
            )
          )
        end

        update_source_user
      end
    end
  end
end
