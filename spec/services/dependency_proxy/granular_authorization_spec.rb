# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DependencyProxy::GranularAuthorization, feature_category: :virtual_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:other_group) { create(:group) }

  before_all do
    group.add_guest(user)
    other_group.add_guest(user)
  end

  describe '.pull_authorized?' do
    subject { described_class.pull_authorized?(token, group) }

    context 'with a granular token scoped to the group' do
      let(:token) do
        create(:granular_pat, user: user, boundary: ::Authz::Boundary.for(group),
          permissions: [:read_dependency_proxy])
      end

      it { is_expected.to be(true) }
    end

    context 'with a granular token scoped to a different group' do
      let(:token) do
        create(:granular_pat, user: user, boundary: ::Authz::Boundary.for(other_group),
          permissions: [:read_dependency_proxy])
      end

      it { is_expected.to be(false) }
    end

    context 'with a granular token holding an unrelated permission' do
      let(:token) do
        create(:granular_pat, user: user, boundary: ::Authz::Boundary.for(group),
          permissions: [:update_dependency_proxy])
      end

      it { is_expected.to be(false) }
    end

    context 'with a legacy token' do
      let(:token) { create(:personal_access_token, user: user) }

      it { is_expected.to be(true) }

      context 'in a namespace enforcing granular tokens' do
        before do
          ::NamespaceSetting.find_by!(namespace_id: group.id).update!(
            enforce_granular_tokens: true,
            granular_tokens_enforced_after: Date.current
          )
        end

        it { is_expected.to be(false) }
      end
    end
  end
end
