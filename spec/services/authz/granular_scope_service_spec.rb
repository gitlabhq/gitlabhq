# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::GranularScopeService, feature_category: :permissions do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:namespace) { create(:namespace, organization: organization) }
  let_it_be(:other_namespace) { create(:namespace, organization: organization) }

  let(:personal_access_token) { create(:personal_access_token, organization: organization) }
  let(:service) { described_class.new(personal_access_token) }

  describe '#add_granular_scopes' do
    subject(:result) { service.add_granular_scopes(scopes_to_add) }

    context 'with a single granular scope' do
      let(:granular_scope) { build(:granular_scope, namespace: namespace) }
      let(:scopes_to_add) { granular_scope }

      it 'adds the granular scope and sets organization_id on both scope and join record' do
        expect(result).to be_success
        expect(result.payload[:granular_scopes]).to contain_exactly(granular_scope)

        pat_granular_scope = personal_access_token.personal_access_token_granular_scopes
          .find_by_granular_scope_id(granular_scope)

        expect(granular_scope.organization_id).to eq(personal_access_token.organization_id)
        expect(pat_granular_scope.organization_id).to eq(personal_access_token.organization_id)
      end

      context 'when adding a duplicate namespace scope' do
        let(:duplicate_scope) { build(:granular_scope, namespace: namespace) }
        let(:scopes_to_add) { duplicate_scope }

        before do
          service.add_granular_scopes(build(:granular_scope, namespace: namespace))
        end

        it 'returns an error and does not add the duplicate scope' do
          expect { result }.not_to change { personal_access_token.granular_scopes.count }
          expect(result).to be_error
          expect(result.message).to eq('The token cannot have multiple granular scopes for the same namespace')
        end
      end

      context 'when adding duplicate instance-level scopes' do
        let(:instance_scope) { build(:granular_scope, :instance) }
        let(:duplicate_instance_scope) { build(:granular_scope, :instance) }
        let(:scopes_to_add) { duplicate_instance_scope }

        before do
          service.add_granular_scopes(instance_scope)
        end

        it 'returns an error for multiple instance-level scopes' do
          expect { result }.not_to change { personal_access_token.granular_scopes.count }
          expect(result).to be_error
          expect(result.message).to eq('The token cannot have multiple instance-level granular scopes')
        end
      end
    end

    context 'with multiple granular scopes' do
      let(:first_scope) { build(:granular_scope, namespace: namespace) }
      let(:second_scope) { build(:granular_scope, namespace: other_namespace) }
      let(:scopes_to_add) { [first_scope, second_scope] }

      it 'adds all granular scopes successfully' do
        expect(result).to be_success
        expect(result.payload[:granular_scopes]).to contain_exactly(first_scope, second_scope)

        expect(personal_access_token.granular_scopes)
          .to contain_exactly(first_scope, second_scope)
        expect(first_scope.organization_id).to eq(personal_access_token.organization_id)
        expect(second_scope.organization_id).to eq(personal_access_token.organization_id)
      end

      context 'when one scope fails validation' do
        let(:duplicate_namespace_scope) { build(:granular_scope, namespace: namespace) }
        let(:valid_scope) { build(:granular_scope, namespace: other_namespace) }
        let(:scopes_to_add) { [duplicate_namespace_scope, valid_scope] }

        before do
          service.add_granular_scopes(build(:granular_scope, namespace: namespace))
        end

        it 'fails fast and does not add any scopes' do
          expect { result }.not_to change { personal_access_token.granular_scopes.count }
          expect(result).to be_error
          expect(result.message).to eq('The token cannot have multiple granular scopes for the same namespace')
          expect(personal_access_token.personal_access_token_granular_scopes.map(&:granular_scope))
            .not_to include(valid_scope)
        end
      end
    end

    context 'with unpersisted personal access token' do
      let(:unpersisted_token) { build(:personal_access_token) }
      let(:service) { described_class.new(unpersisted_token) }
      let(:first_scope) { build(:granular_scope, namespace: namespace) }
      let(:duplicate_scope) { build(:granular_scope, namespace: namespace) }

      it 'validates against in-memory granular scopes' do
        result = service.add_granular_scopes(first_scope)
        expect(result).to be_success

        result = service.add_granular_scopes(duplicate_scope)
        expect(result).to be_error
        expect(result.message).to eq('The token cannot have multiple granular scopes for the same namespace')
      end
    end

    context 'with loaded granular scopes association' do
      before do
        existing_scope = build(:granular_scope, namespace: namespace)
        service.add_granular_scopes(existing_scope)
        personal_access_token.granular_scopes.to_a
      end

      it 'validates against loaded association when adding duplicate namespace' do
        expect(personal_access_token.granular_scopes.loaded?).to be(true)

        duplicate_scope = build(:granular_scope, namespace: namespace)
        result = service.add_granular_scopes(duplicate_scope)

        expect(result).to be_error
        expect(result.message).to eq('The token cannot have multiple granular scopes for the same namespace')
      end

      it 'validates against loaded association when adding to different namespace' do
        expect(personal_access_token.granular_scopes.loaded?).to be(true)

        different_namespace_scope = build(:granular_scope, namespace: other_namespace)
        result = service.add_granular_scopes(different_namespace_scope)

        expect(result).to be_success
        expect(personal_access_token.reload.granular_scopes).to include(different_namespace_scope)
      end
    end
  end
end
