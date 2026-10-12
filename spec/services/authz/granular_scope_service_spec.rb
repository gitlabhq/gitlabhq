# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::GranularScopeService, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:organization) { create(:organization) }
  let_it_be(:namespace) { create(:group, organization: organization) }
  let_it_be(:namespace_boundary) { ::Authz::Boundary.for(namespace) }
  let_it_be(:other_namespace) { create(:group, organization: organization) }
  let_it_be(:other_namespace_boundary) { ::Authz::Boundary.for(other_namespace) }
  let_it_be(:instance_boundary) { ::Authz::Boundary.for(:instance) }
  let_it_be(:user_boundary) { ::Authz::Boundary.for(:user) }

  let(:personal_access_token) { create(:personal_access_token, organization: organization) }
  let(:service) { described_class.new(personal_access_token) }

  shared_examples 'rejects the scopes and adds nothing' do
    it 'returns the error and builds no join rows', :aggregate_failures do
      expect { result }.not_to change { personal_access_token.personal_access_token_granular_scopes.size }
      expect(result).to be_error
      expect(result.message).to eq(expected_message)
    end
  end

  describe '#add_granular_scopes' do
    subject(:result) { service.add_granular_scopes(scopes_to_add) }

    context 'with scopes for distinct namespaces' do
      let(:first_scope) { build(:granular_scope, boundary: namespace_boundary) }
      let(:second_scope) { build(:granular_scope, boundary: other_namespace_boundary) }
      let(:scopes_to_add) { [first_scope, second_scope] }

      it 'adds the scopes and sets organization_id on the scopes and their join rows', :aggregate_failures do
        organization_id = personal_access_token.organization_id

        expect(result).to be_success
        expect(result.payload[:granular_scopes]).to contain_exactly(first_scope, second_scope)
        expect(personal_access_token.granular_scopes).to contain_exactly(first_scope, second_scope)
        expect([first_scope, second_scope]).to all(have_attributes(organization_id: organization_id))
        expect(personal_access_token.reload.personal_access_token_granular_scopes)
          .to all(have_attributes(organization_id: organization_id))
      end
    end

    context 'when a scope duplicates another' do
      where(:boundary, :expected_message) do
        ref(:namespace_boundary) | 'The token cannot have multiple granular scopes for the same namespace'
        ref(:instance_boundary)  | 'The token cannot have multiple granular scopes with the same access level'
        ref(:user_boundary)      | 'The token cannot have multiple granular scopes with the same access level'
      end

      with_them do
        let(:valid_scope) { build(:granular_scope, boundary: other_namespace_boundary) }

        context 'when the duplicate is in the same call' do
          let(:scopes_to_add) do
            [build(:granular_scope, boundary: boundary), valid_scope, build(:granular_scope, boundary: boundary)]
          end

          it_behaves_like 'rejects the scopes and adds nothing'
        end

        context 'when the duplicate is already on the token' do
          let(:scopes_to_add) { [valid_scope, build(:granular_scope, boundary: boundary)] }

          before do
            service.add_granular_scopes(build(:granular_scope, boundary: boundary))
          end

          it_behaves_like 'rejects the scopes and adds nothing'
        end
      end
    end

    context 'when the token already holds a different standalone scope' do
      let(:scopes_to_add) { build(:granular_scope, boundary: ::Authz::Boundary.for(:user)) }

      before do
        service.add_granular_scopes(build(:granular_scope, boundary: instance_boundary))
      end

      it 'adds the scope alongside the existing one', :aggregate_failures do
        expect(result).to be_success
        expect(personal_access_token.granular_scopes.map(&:access)).to contain_exactly('instance', 'user')
      end
    end

    context 'when the token is loaded from the database with saved scopes' do
      let_it_be(:saved_token) do
        create(:granular_pat,
          organization: organization, boundary: namespace_boundary, permissions: [:create_member_role])
      end

      let(:personal_access_token) { PersonalAccessToken.find(saved_token.id) }

      context 'and a scope targets a namespace the token already has' do
        let(:scopes_to_add) { build(:granular_scope, boundary: namespace_boundary) }
        let(:expected_message) { 'The token cannot have multiple granular scopes for the same namespace' }

        it_behaves_like 'rejects the scopes and adds nothing'
      end

      context 'and a scope targets another namespace' do
        let(:scopes_to_add) { build(:granular_scope, boundary: other_namespace_boundary) }

        it 'adds the scope next to the saved one', :aggregate_failures do
          expect(result).to be_success
          expect(PersonalAccessToken.find(saved_token.id).granular_scopes.map(&:namespace_id))
            .to contain_exactly(namespace.id, other_namespace.id)
        end
      end
    end

    context 'with unpersisted personal access token' do
      let(:unpersisted_token) { build(:personal_access_token) }
      let(:service) { described_class.new(unpersisted_token) }
      let(:first_scope) { build(:granular_scope, boundary: namespace_boundary) }
      let(:duplicate_scope) { build(:granular_scope, boundary: namespace_boundary) }

      it 'validates against in-memory granular scopes', :aggregate_failures do
        result = service.add_granular_scopes(first_scope)
        expect(result).to be_success

        result = service.add_granular_scopes(duplicate_scope)
        expect(result).to be_error
        expect(result.message).to eq('The token cannot have multiple granular scopes for the same namespace')
      end
    end
  end
end
