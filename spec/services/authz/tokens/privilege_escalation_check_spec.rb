# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Tokens::PrivilegeEscalationCheck, feature_category: :permissions do
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:user_boundary) { Authz::Boundary.for(:user) }

  subject(:check) { described_class.new(requested_scopes, authenticating_token) }

  describe '#execute' do
    let(:requested_scopes) { [Authz::GranularScope.new(access: :user, permissions: [:read_job])] }

    context 'when there is no authenticating token' do
      let(:authenticating_token) { nil }

      it 'returns a successful response' do
        expect(check.execute).to be_success
      end
    end

    context 'when the authenticating token is not granular' do
      let(:authenticating_token) { create(:personal_access_token, user: user) }

      it 'returns a successful response' do
        expect(check.execute).to be_success
      end
    end

    context 'when the authenticating token does not respond to granular?' do
      let(:authenticating_token) { create(:oauth_access_token) }

      it 'returns a successful response' do
        expect(check.execute).to be_success
      end
    end

    context 'when the authenticating token is granular' do
      let_it_be(:authenticating_token) do
        create(:granular_pat, user: user, boundary: user_boundary, permissions: [:create_personal_access_token])
      end

      context 'when requested_scopes is empty' do
        let(:requested_scopes) { [] }

        it 'returns a successful response' do
          expect(check.execute).to be_success
        end
      end

      context 'when the requested scope requests permissions the authenticating token does not have' do
        it 'returns an error response' do
          result = check.execute

          expect(result).to be_error
          expect(result.message).to eq('A granular token can only create tokens with equal or lesser permissions.')
          expect(result.reason).to eq(:forbidden)
        end
      end

      context 'when the requested scope requests permissions the authenticating token already has' do
        let(:requested_scopes) do
          [Authz::GranularScope.new(access: :user, permissions: [:create_personal_access_token])]
        end

        it 'returns a successful response' do
          expect(check.execute).to be_success
        end
      end

      context 'when the requested scope has no permissions' do
        let(:requested_scopes) { [Authz::GranularScope.new(access: :user, permissions: [])] }

        it 'returns a successful response' do
          expect(check.execute).to be_success
        end
      end

      context 'when the requested token has a different boundary than the authenticating token' do
        let(:requested_scopes) do
          [Authz::GranularScope.new(access: :selected_memberships, permissions: [:read_job],
            namespace: create(:group))]
        end

        it 'returns an error response' do
          result = check.execute

          expect(result).to be_error
          expect(result.message).to eq('A granular token can only create tokens with equal or lesser permissions.')
          expect(result.reason).to eq(:forbidden)
        end
      end
    end

    context 'when the authenticating token has all_memberships scope' do
      let(:all_memberships_boundary) { Authz::Boundary.for(:all_memberships) }
      let(:authenticating_token) do
        token = create(:granular_pat, user: user, boundary: user_boundary,
          permissions: [:create_personal_access_token])
        all_memberships_scope = create(:granular_scope,
          boundary: all_memberships_boundary,
          permissions: [:read_job],
          organization: token.organization)
        create(:personal_access_token_granular_scope,
          personal_access_token: token,
          granular_scope: all_memberships_scope,
          organization: token.organization)
        token
      end

      context 'when the requested token has a personal_projects scope' do
        let(:requested_scopes) do
          [Authz::GranularScope.new(access: :personal_projects, permissions: [:read_job], namespace: user.namespace)]
        end

        it 'returns a successful response' do
          expect(check.execute).to be_success
        end
      end

      context 'when the requested token has a selected_memberships scope' do
        let(:requested_scopes) do
          [Authz::GranularScope.new(access: :selected_memberships, permissions: [:read_job],
            namespace: create(:group))]
        end

        it 'returns a successful response' do
          expect(check.execute).to be_success
        end
      end
    end

    context 'when the authenticating token has selected_memberships scope on a parent group' do
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:subgroup) { create(:group, parent: parent_group) }

      let(:parent_boundary) { Authz::Boundary.for(parent_group) }
      let(:authenticating_token) do
        token = create(:granular_pat, user: user, boundary: user_boundary,
          permissions: [:create_personal_access_token])
        parent_scope = create(:granular_scope,
          boundary: parent_boundary,
          permissions: [:read_job],
          organization: token.organization)
        create(:personal_access_token_granular_scope,
          personal_access_token: token,
          granular_scope: parent_scope,
          organization: token.organization)
        token
      end

      let(:requested_scopes) do
        [Authz::GranularScope.new(access: :selected_memberships, permissions: [:read_job], namespace: subgroup)]
      end

      it 'returns a successful response for a selected_memberships scope on a sub-group' do
        expect(check.execute).to be_success
      end
    end
  end
end
