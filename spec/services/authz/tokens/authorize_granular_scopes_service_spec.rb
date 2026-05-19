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

      it_behaves_like 'error response', 'Access denied: Fine-grained personal access tokens are not yet supported.'
    end

    context 'when the token is missing' do
      let(:token) { nil }

      it_behaves_like 'successful response'
    end

    context 'when the boundary is missing' do
      let(:boundary) { nil }

      it_behaves_like 'error response', '404 Not Found'
    end

    context 'when no valid boundaries are passed in' do
      let(:boundary) { [nil, ' '] }

      it_behaves_like 'error response', '404 Not Found'
    end

    context 'when permissions are missing' do
      let(:permissions) { nil }

      it_behaves_like 'error response',
        "Access denied: This operation doesn't support fine-grained personal access tokens."
    end

    context 'when both boundary and permissions are missing' do
      let(:boundary) { nil }
      let(:permissions) { nil }

      it_behaves_like 'error response',
        "Access denied: This operation doesn't support fine-grained personal access tokens."
    end

    context 'when the token does not support fine-grained permissions' do
      let(:token) { build(:oauth_access_token) }

      it_behaves_like 'successful response'
    end

    context 'when the token is a legacy personal access token' do
      let(:token) { build(:personal_access_token) }

      it_behaves_like 'successful response'

      context 'when the namespace requires granular tokens' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, :in_group) }
        let_it_be(:boundary) { Authz::Boundary.for(group) }

        before do
          stub_feature_flags(granular_personal_access_tokens_enforcement_saas: group)

          group.namespace_settings.update!(
            enforce_granular_tokens: true,
            granular_tokens_enforced_after: Date.current
          )
        end

        it_behaves_like 'error response',
          'Access denied: This operation requires a fine-grained personal access token ' \
            'with the following group permissions: [Member Role: Create].'

        it 'does not have N+1 queries' do
          control = ActiveRecord::QueryRecorder.new do
            service.execute
          end

          expect do
            described_class.new(
              boundaries: [
                Authz::Boundary.for(group.reload),
                Authz::Boundary.for(project.reload)
              ],
              permissions: permissions,
              token: token
            ).execute
          end.to issue_same_number_of_queries_as(control).or_fewer
        end

        context 'when the `granular_personal_access_tokens` feature flag is disabled' do
          before do
            stub_feature_flags(granular_personal_access_tokens: false)
          end

          it_behaves_like 'successful response'
        end

        context 'when the `granular_personal_access_tokens_enforcement_saas` feature flag is disabled' do
          before do
            stub_feature_flags(granular_personal_access_tokens_enforcement_saas: false)
          end

          it_behaves_like 'successful response'
        end

        context 'when `granular_personal_access_tokens_enforcement_saas` FF is enabled for a different namespace' do
          before do
            stub_feature_flags(granular_personal_access_tokens_enforcement_saas: create(:group))
          end

          it_behaves_like 'successful response'
        end

        context 'when `granular_personal_access_tokens_enforcement_saas` FF is not enabled for root' do
          let_it_be(:sub_group) { create(:group, parent: group) }
          let_it_be(:boundary) { Authz::Boundary.for(sub_group) }

          before do
            stub_feature_flags(granular_personal_access_tokens_enforcement_saas: sub_group)
          end

          it_behaves_like 'successful response'
        end
      end
    end

    context 'when the token does not have the required permissions' do
      let_it_be(:granular_pat) { create(:granular_pat, boundary: boundary, permissions: :read_work_item) }
      let_it_be(:permissions) { [:read_issue, :read_epic, :read_fork] }

      it_behaves_like 'error response', 'Access denied: This operation requires a fine-grained personal access token ' \
        'with the following instance permissions: [Project: Read, Work Item: Read].'
    end

    context 'when the boundary is not visible to the user' do
      let_it_be(:private_project) { create(:project, :private) }
      let_it_be(:boundary) { Authz::Boundary.for(private_project) }
      let_it_be(:permissions) { :read_code }
      let_it_be(:granular_pat) { create(:granular_pat) }

      it 'returns a resource_not_found error response' do
        result = service.execute

        expect(result).to be_error
        expect(result.reason).to eq(:resource_not_found)
        expect(result.message).to eq('404 Not Found')
      end

      context 'when the user is a member of the boundary' do
        before_all do
          private_project.add_developer(token.user)
        end

        it 'returns an access_denied error response' do
          result = service.execute

          expect(result).to be_error
          expect(result.reason).to be_nil
          expect(result.message).to start_with('Access denied:')
        end
      end

      context 'when one of the multiple boundaries is hidden' do
        let_it_be(:public_group) { create(:group, :public) }
        let_it_be(:boundary) { [Authz::Boundary.for(private_project), Authz::Boundary.for(public_group)] }

        it 'hides existence by returning resource_not_found' do
          result = service.execute

          expect(result).to be_error
          expect(result.reason).to eq(:resource_not_found)
        end
      end
    end

    context 'when permissions are declared but no boundary resolves' do
      let_it_be(:boundary) { nil }
      let_it_be(:permissions) { :read_code }
      let_it_be(:granular_pat) { create(:granular_pat) }

      it_behaves_like 'error response', '404 Not Found'

      it 'sets reason to :resource_not_found so callers can render a 404' do
        expect(service.execute.reason).to eq(:resource_not_found)
      end
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
          allow(token).to receive(:can?).with(:read_boundary, anything).and_call_original
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

          expect(result.message).to eq('Access denied: This operation requires a fine-grained personal access token ' \
            'with the following project permissions: [Member Role: Delete].')
          expect(result).to be_error
        end
      end
    end
  end
end
