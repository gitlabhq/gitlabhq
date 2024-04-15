# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Achievements::Create, feature_category: :user_profile do
  include GraphqlHelpers
  include WorkhorseHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:group) { create(:group, developers: developer, maintainers: maintainer) }

  let(:mutation) { graphql_mutation(:achievements_create, params) }
  let(:name) { 'Name' }
  let(:description) { 'Description' }
  let(:avatar) { fixture_file_upload("spec/fixtures/dk.png") }
  let(:params) do
    {
      namespace_id: group.to_global_id,
      name: name,
      avatar: avatar,
      description: description
    }
  end

  subject { post_graphql_mutation_with_uploads(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:achievements_create)
  end

  context 'when the user does not have permission' do
    let(:current_user) { developer }
    let(:avatar) {}

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not create an achievement' do
      expect { subject }.not_to change { Achievements::Achievement.count }
    end
  end

  context 'when the user has permission' do
    let(:current_user) { maintainer }

    context 'when the params are invalid' do
      let(:name) {}

      it 'returns the validation error' do
        subject

        expect(graphql_errors.to_s).to include('provided invalid value for name (Expected value to not be null)')
      end
    end

    it 'creates an achievement' do
      expect { subject }.to change { Achievements::Achievement.count }.by(1)
    end

    it 'returns the new achievement' do
      subject

      expect(graphql_data_at(:achievements_create, :achievement)).to match a_hash_including(
        'name' => name,
        'namespace' => a_hash_including('id' => group.to_global_id.to_s),
        'description' => description
      )
    end
  end
end
