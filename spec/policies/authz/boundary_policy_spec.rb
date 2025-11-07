# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::BoundaryPolicy, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:root_group) { create(:group) }
  let_it_be(:group) { create(:group, parent: root_group) }
  let_it_be(:user) { create(:user, :with_namespace, developer_of: root_group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:instance) { nil }
  let_it_be(:permissions) { :create_issue }

  let(:boundary_object) { project }
  let(:boundary) { Authz::Boundary.for(boundary_object) }
  let(:token) { create(:granular_pat, user: user, namespace: boundary.namespace, permissions: permissions) }

  subject(:policy) { described_class.new(token, boundary) }

  context 'when the policy actor is not a PAT' do
    let(:token) { create(:oauth_access_token) }

    it { is_expected.to be_disallowed(*permissions) }
  end

  context 'when the PAT is not granular' do
    before do
      token.granular = false
    end

    it { is_expected.to be_disallowed(*permissions) }
  end

  context 'when a permission is not allowed' do
    it { is_expected.to be_disallowed(:not_allowed_permission) }
  end

  context 'when the user is not a member' do
    let_it_be(:user) { create(:user) }

    it { is_expected.to be_disallowed(*permissions) }
  end

  context 'with different boundary types' do
    where(:boundary_object) do
      [
        ref(:group),
        ref(:project),
        ref(:user),
        ref(:instance)
      ]
    end

    with_them do
      it { is_expected.to be_allowed(*permissions) }
    end
  end
end
