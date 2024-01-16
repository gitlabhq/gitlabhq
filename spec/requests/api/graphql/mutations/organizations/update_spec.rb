# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Organizations::Update, feature_category: :cell do
  include GraphqlHelpers
  include WorkhorseHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:organization) do
    create(:organization) { |org| create(:organization_user, :owner, organization: org, user: user) }
  end

  let(:mutation) { graphql_mutation(:organization_update, params) }
  let(:name) { 'Name' }
  let(:path) { 'path' }
  let(:description) { 'org-description' }
  let(:avatar) { nil }
  let(:params) do
    {
      id: organization.to_global_id.to_s,
      name: name,
      path: path,
      description: description,
      avatar: avatar
    }
  end

  subject(:update_organization) { post_graphql_mutation_with_uploads(mutation, current_user: current_user) }

  it { expect(described_class).to require_graphql_authorizations(:admin_organization) }

  def mutation_response
    graphql_mutation_response(:organization_update)
  end

  context 'when the user does not have permission' do
    let(:current_user) { nil }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not update the organization' do
      initial_name = organization.name
      initial_path = organization.path

      update_organization
      organization.reset

      expect(organization.name).to eq(initial_name)
      expect(organization.path).to eq(initial_path)
    end
  end

  context 'when the user has permission' do
    let(:current_user) { user }

    context 'when the params are invalid' do
      let(:name) { '' }

      it 'returns the validation error' do
        update_organization

        expect(mutation_response).to include('errors' => ["Name can't be blank"])
      end
    end

    context 'when single attribute is update' do
      using RSpec::Parameterized::TableSyntax

      where(attribute: %w[name path description])

      with_them do
        let(:value) { "new-#{attribute}" }
        let(:attribute_hash) { { attribute => value } }
        let(:params) { { id: organization.to_global_id.to_s }.merge(attribute_hash) }

        it 'updates the given field' do
          update_organization

          expect(graphql_data_at(:organization_update, :organization)).to match a_hash_including(attribute_hash)
          expect(mutation_response['errors']).to be_empty
        end
      end
    end

    it 'returns the updated organization' do
      update_organization

      expect(graphql_data_at(:organization_update, :organization)).to match a_hash_including(
        'name' => name,
        'path' => path,
        'description' => description
      )
      expect(mutation_response['errors']).to be_empty
    end

    context 'with a new avatar' do
      let(:filename) { 'spec/fixtures/dk.png' }
      let(:avatar) { fixture_file_upload(filename) }

      it 'returns the updated organization' do
        update_organization

        expect(
          graphql_data_at(:organization_update, :organization)
        ).to(
          match(
            a_hash_including(
              'name' => name,
              'path' => path,
              'description' => description
            )
          )
        )
        expect(File.basename(organization.reload.avatar.file.file)).to eq(File.basename(filename))
        expect(mutation_response['errors']).to be_empty
      end
    end
  end
end
