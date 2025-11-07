# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authz::Boundary, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:group) { create(:group, developers: user) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:standalone) { nil }

  describe '.declarative_policy_class' do
    subject { described_class::Base.declarative_policy_class }

    it { is_expected.to eq('Authz::BoundaryPolicy') }
  end

  describe '#namespace' do
    subject { described_class.for(boundary).namespace }

    context 'when boundary is a group' do
      let(:boundary) { group }

      it { is_expected.to eq(group) }
    end

    context 'when boundary is a project' do
      let(:boundary) { project }

      it { is_expected.to eq(project.project_namespace) }
    end

    context 'when boundary is a user' do
      let(:boundary) { user }

      it { is_expected.to eq(user.namespace) }
    end

    context 'when boundary is standalone' do
      let(:boundary) { standalone }

      it { is_expected.to be_nil }
    end
  end

  describe 'path' do
    subject { described_class.for(boundary).path }

    context 'when boundary is a group' do
      let(:boundary) { group }

      it { is_expected.to eq(group.full_path) }
    end

    context 'when boundary is a project' do
      let(:boundary) { project }

      it { is_expected.to eq(project.project_namespace.full_path) }
    end

    context 'when boundary is a user' do
      let(:boundary) { user }

      it { is_expected.to eq(user.namespace.full_path) }
    end

    context 'when boundary is standalone' do
      let(:boundary) { standalone }

      it { is_expected.to be_nil }
    end
  end

  describe '#member?' do
    let_it_be(:other_user) { create(:user) }

    subject { described_class.for(boundary).member?(member_user) }

    where(:boundary, :member_user, :result) do
      ref(:group)      | ref(:user)       | true
      ref(:group)      | ref(:other_user) | false
      ref(:project)    | ref(:user)       | true
      ref(:project)    | ref(:other_user) | false
      ref(:user)       | ref(:user)       | true
      ref(:user)       | ref(:other_user) | false
      ref(:standalone) | ref(:user)       | true
      ref(:standalone) | ref(:other_user) | true
    end

    with_them do
      it { is_expected.to be(result) }
    end
  end
end
