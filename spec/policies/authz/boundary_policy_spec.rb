# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::BoundaryPolicy, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:root_group) { create(:group) }
  let_it_be(:group) { create(:group, parent: root_group) }
  let_it_be(:user) { create(:user, :with_namespace, developer_of: root_group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:permissions) { :update_wiki }

  let(:boundary_object) { project }
  let(:boundary) { Authz::Boundary.for(boundary_object) }
  let(:token) { create(:granular_pat, user:, boundary:, permissions:) }

  subject(:policy) { described_class.new(token, boundary) }

  context 'when the policy actor is not a PAT' do
    let(:token) { create(:oauth_access_token) }

    it { expect_disallowed(*permissions) }
  end

  context 'when the PAT is not granular' do
    before do
      token.granular = false
    end

    it { expect_disallowed(*permissions) }
  end

  context 'when a permission is not allowed' do
    it { expect_disallowed(:not_allowed_permission) }
  end

  context 'when the user is not a member' do
    let_it_be(:user) { create(:user) }

    it { expect_disallowed(*permissions) }

    context 'when the user is an admin', :enable_admin_mode do
      let_it_be(:user) { create(:admin) }

      it { expect_allowed(*permissions) }
    end
  end

  context 'with different boundary types' do
    where(:boundary_object) do
      [
        ref(:group),
        ref(:project),
        :instance,
        :user
      ]
    end

    with_them do
      it { expect_allowed(*permissions) }
    end
  end

  describe ':read_boundary' do
    subject(:visible) { policy.allowed?(:read_boundary) }

    context 'when the user is a member of the boundary' do
      it { is_expected.to be(true) }
    end

    context 'when the user is not a member' do
      let_it_be(:user) { create(:user) }

      context 'and the boundary is a private project' do
        let_it_be(:boundary_object) { create(:project, :private) }

        it { is_expected.to be(false) }
      end

      context 'and the boundary is an internal project' do
        let_it_be(:boundary_object) { create(:project, :internal) }

        it { is_expected.to be(true) }
      end

      context 'and the boundary is a public project' do
        let_it_be(:boundary_object) { create(:project, :public) }

        it { is_expected.to be(true) }
      end

      context 'and the boundary is a private group' do
        let_it_be(:boundary_object) { create(:group, :private) }

        it { is_expected.to be(false) }
      end

      context 'and the boundary is an internal group' do
        let_it_be(:boundary_object) { create(:group, :internal) }

        it { is_expected.to be(true) }
      end

      context 'and the boundary is a public group' do
        let_it_be(:boundary_object) { create(:group, :public) }

        it { is_expected.to be(true) }
      end

      context 'and the user is an admin', :enable_admin_mode do
        let_it_be(:user) { create(:admin) }
        let_it_be(:boundary_object) { create(:project, :private) }

        it { is_expected.to be(true) }
      end
    end
  end

  describe 'public-access bypass' do
    let_it_be(:public_project) { create(:project, :public) }
    let_it_be(:public_group) { create(:group, :public) }
    let_it_be(:user) { create(:user) }
    let_it_be(:token) { create(:granular_pat, user:) }

    let(:permission) { :read_issue }
    let(:resource_policy) { instance_double(::DeclarativePolicy::Base) }

    before do
      allow(::DeclarativePolicy).to receive(:policy_for).and_call_original
      allow(::DeclarativePolicy).to receive(:policy_for)
        .with(nil, boundary_object, hash_including(:cache)).and_return(resource_policy)
    end

    shared_examples 'mirrors the anonymous policy outcome' do
      context 'when an anonymous caller would be granted the permission' do
        before do
          allow(resource_policy).to receive(:allowed?).with(permission).and_return(true)
        end

        it { expect_allowed(permission) }
      end

      context 'when an anonymous caller would be denied the permission' do
        before do
          allow(resource_policy).to receive(:allowed?).with(permission).and_return(false)
        end

        it { expect_disallowed(permission) }
      end
    end

    context 'with a project boundary' do
      let(:boundary_object) { public_project }

      it_behaves_like 'mirrors the anonymous policy outcome'
    end

    context 'with a group boundary' do
      let(:boundary_object) { public_group }

      it_behaves_like 'mirrors the anonymous policy outcome'
    end

    context 'when the boundary resource is neither a project nor a group' do
      let(:boundary_object) { :instance }

      it 'does not consult the anonymous-parity bypass' do
        expect(::DeclarativePolicy).not_to receive(:policy_for).with(nil, anything, anything)
        policy.allowed?(permission)
      end
    end
  end
end
