# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Organizations::Create, feature_category: :cell do
  include GraphqlHelpers
  include WorkhorseHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:organization) { create(:organization) }

  let(:mutation) { graphql_mutation(:organization_create, params) }
  let(:name) { 'Name' }
  let(:path) { 'path' }
  let(:description) { nil }
  let(:avatar) { fixture_file_upload("spec/fixtures/dk.png") }
  let(:params) do
    {
      name: name,
      path: path,
      avatar: avatar
    }
  end

  subject(:create_organization) { post_graphql_mutation_with_uploads(mutation, current_user: current_user) }

  it { expect(described_class).to require_graphql_authorizations(:create_organization) }

  def mutation_response
    graphql_mutation_response(:organization_create)
  end

  context 'when the user does not have permission' do
    let(:current_user) { nil }
    let(:avatar) { nil }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not create an organization' do
      expect { create_organization }.not_to change { Organizations::Organization.count }
    end
  end

  context 'when the user has permission' do
    let(:current_user) { user }

    context 'when the params are invalid' do
      let(:name) { '' }

      it 'returns the validation error' do
        create_organization

        expect(mutation_response).to include('errors' => ["Name can't be blank"])
      end
    end

    shared_examples 'creating an organization' do
      it 'creates an organization' do
        expect { create_organization }.to change { Organizations::Organization.count }.by(1)
      end

      it 'returns the new organization' do
        create_organization

        expect(graphql_data_at(:organization_create, :organization)).to match a_hash_including(
          'name' => name,
          'path' => path,
          'description' => description
        )
      end
    end

    context 'with description' do
      let(:description) { 'Organization description' }
      let(:params) do
        {
          name: name,
          path: path,
          description: description
        }
      end

      include_examples 'creating an organization'
    end

    include_examples 'creating an organization'
  end
end
