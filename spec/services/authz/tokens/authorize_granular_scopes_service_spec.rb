# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authz::Tokens::AuthorizeGranularScopesService, feature_category: :permissions do
  let_it_be(:boundary) { Authz::Boundary.for(:instance) }
  let_it_be(:granular_pat) { create(:granular_pat, boundary: boundary, permissions: :create_member_role) }
  let_it_be(:token) { granular_pat }
  let_it_be(:permissions) { :create_member_role }

  subject(:service) { described_class.new(boundaries: boundary, permissions: permissions, token: token) }

  shared_examples 'successful response' do
    it 'returns ServiceResponse.success' do
      result = service.execute

      expect(result).to be_a(ServiceResponse)
      expect(result.success?).to be(true)
    end
  end

  shared_examples 'error response' do |message|
    it 'returns ServiceResponse.error' do
      result = service.execute

      expect(result).to be_a(ServiceResponse)
      expect(result.error?).to be(true)
      expect(result.message).to eq(message)
    end
  end

  describe '#initialize' do
    context 'when the passed boundary is not an Authz::Boundary' do
      let(:boundary) { build(:project) }

      it 'raises an InvalidInputError error' do
        expect { service }.to raise_error(Authz::Tokens::AuthorizeGranularScopesService::InvalidInputError,
          'Boundaries must be instances of Authz::Boundary::Base, got Project')
      end
    end

    context 'when none of the passed boundaries are Authz::Boundary' do
      let(:boundary) { [build(:project), build(:group)] }

      it 'raises an InvalidInputError error' do
        expect { service }.to raise_error(Authz::Tokens::AuthorizeGranularScopesService::InvalidInputError,
          'Boundaries must be instances of Authz::Boundary::Base, got Project, Group')
      end
    end

    context 'when the passed permissions are not valid' do
      let(:permissions) { [:a, :b, :create_member_role] }

      it 'raises an InvalidInputError error' do
        expect { service }.to raise_error(Authz::Tokens::AuthorizeGranularScopesService::InvalidInputError,
          'Invalid permissions: a, b')
      end
    end
  end

  describe '#execute' do
    it_behaves_like 'successful response'

    context 'when the `granular_personal_access_tokens` feature flag is disabled' do
      before do
        stub_feature_flags(granular_personal_access_tokens: false)
      end

      it_behaves_like 'error response', 'Granular tokens are not yet supported'
    end

    context 'when the token is missing' do
      let(:token) { nil }

      it_behaves_like 'successful response'
    end

    context 'when the boundary is missing' do
      let(:boundary) { nil }

      it_behaves_like 'error response', 'Unable to determine boundaries for authorization'
    end

    context 'when no valid boundaries are passed in' do
      let(:boundary) { [nil, ' '] }

      it_behaves_like 'error response', 'Unable to determine boundaries for authorization'
    end

    context 'when permissions are missing' do
      let(:permissions) { nil }

      it_behaves_like 'error response', 'Unable to determine permissions for authorization'
    end

    context 'when the token does not support fine-grained permissions' do
      let(:token) { build(:oauth_access_token) }

      it_behaves_like 'successful response'
    end

    context 'when the token is supported, but is not granular' do
      let(:token) { build(:personal_access_token) }

      it_behaves_like 'successful response'

      context 'when the namespace requires granular tokens' do
        before do
          allow(service).to receive(:granular_token_required?).and_return(true)
        end

        it_behaves_like 'error response', 'Access denied: Your Personal Access Token lacks the required permissions: ' \
          '[create_member_role].'
      end
    end

    context 'when the token does not have the required permissions' do
      let_it_be(:permissions) { [:create_member_role, :delete_member_role, :read_member_role] }

      it_behaves_like 'error response', 'Access denied: Your Personal Access Token lacks the required permissions: ' \
        '[delete_member_role, read_member_role].'
    end

    describe 'boundary prioritization' do
      def create_granular_scope(boundary, permissions)
        create(:granular_scope, boundary:, permissions:)
      end

      let_it_be(:token) { create(:granular_pat) }
      let_it_be(:instance_boundary) { Authz::Boundary.for(:instance) }
      let_it_be(:user_boundary) { Authz::Boundary.for(:user) }
      let_it_be(:group_boundary) { Authz::Boundary.for(create(:group, developers: token.user)) }
      let_it_be(:project_boundary) { Authz::Boundary.for(create(:project, developers: token.user)) }
      let_it_be(:instance_scope) { create_granular_scope(instance_boundary, [:delete_member_role]) }
      let_it_be(:user_scope) { create_granular_scope(user_boundary, [:read_member_role]) }
      let_it_be(:project_scope) { create_granular_scope(project_boundary, [:create_member_role]) }
      let_it_be(:group_scope) { create_granular_scope(group_boundary, [:create_member_role]) }

      before do
        ::Authz::GranularScopeService.new(token).add_granular_scopes(
          [project_scope, group_scope, user_scope, instance_scope]
        )
      end

      context 'when the token has the required permissions for some of the boundaries' do
        let_it_be(:boundary) { [instance_boundary, group_boundary, project_boundary] }

        # In this case the authorization succeeds on the project boundary. The
        # group and instance boundaries are no longer checked.
        it 'returns result of the first successful authorization' do
          expect(token).to receive(:can?).with(:create_member_role, project_boundary).and_call_original
          expect(token).not_to receive(:can?).with(:create_member_role, group_boundary)
          expect(token).not_to receive(:can?).with(:create_member_role, instance_boundary)

          result = service.execute

          expect(result.success?).to be(true)
        end
      end

      context 'when the token has the required permissions for only one of the boundaries' do
        let_it_be(:boundary) { [user_boundary, instance_boundary, group_boundary, project_boundary] }
        let_it_be(:permissions) { :delete_member_role }

        it 'authorizes based on boundary priority order' do
          expect(token).to receive(:can?).with(:delete_member_role, project_boundary).and_call_original.ordered
          expect(token).to receive(:can?).with(:delete_member_role, group_boundary).and_call_original.ordered
          expect(token).to receive(:can?).with(:delete_member_role, user_boundary).and_call_original.ordered
          expect(token).to receive(:can?).with(:delete_member_role, instance_boundary).and_call_original.ordered

          result = service.execute

          expect(result.success?).to be(true)
        end
      end

      context 'when the token does not have the required permissions' do
        let_it_be(:boundary) { [user_boundary, project_boundary] }
        let_it_be(:permissions) { :delete_member_role }

        it 'returns the correct error message' do
          result = service.execute

          project_boundary_message = "[delete_member_role] for \"#{project_boundary.path}\""
          user_boundary_message = "[delete_member_role]"
          expect(result.message).to eq("Access denied: Your Personal Access Token lacks the required permissions: " \
            "#{project_boundary_message}, #{user_boundary_message}.")
          expect(result).to be_error
        end
      end
    end
  end
end
