# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authz::Boundary, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:group) { create(:group, developers: user) }
  let_it_be(:project) { create(:project, namespace: group) }

  describe '.declarative_policy_class' do
    subject { described_class::Base.declarative_policy_class }

    it { is_expected.to eq('Authz::BoundaryPolicy') }
  end

  describe '.for' do
    subject { described_class.for(boundary) }

    where(:boundary, :result) do
      ref(:group)      | described_class::GroupBoundary
      ref(:project)    | described_class::ProjectBoundary
      ref(:user)       | described_class::PersonalProjectsBoundary
      :all_memberships | described_class::NilBoundary
      :user            | described_class::NilBoundary
      :instance        | described_class::NilBoundary
      :something_else  | NilClass
    end

    with_them do
      it { is_expected.to be_a(result) }
    end
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

    context 'when boundary is :all_memberships' do
      let(:boundary) { :all_memberships }

      it { is_expected.to be_nil }
    end

    context 'when boundary is :user' do
      let(:boundary) { :user }

      it { is_expected.to be_nil }
    end

    context 'when boundary is :instance' do
      let(:boundary) { :instance }

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

      context 'when the user has no namespace' do
        let(:user) { create(:user) }

        it { is_expected.to be_nil }
      end
    end

    context 'when boundary is :all_memberships' do
      let(:boundary) { :all_memberships }

      it { is_expected.to be_nil }
    end

    context 'when boundary is :user' do
      let(:boundary) { :user }

      it { is_expected.to be_nil }
    end

    context 'when boundary is :instance' do
      let(:boundary) { :instance }

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
      :all_memberships | ref(:user)       | true
      :user            | ref(:user)       | true
      :instance        | ref(:user)       | true
    end

    with_them do
      it { is_expected.to be(result) }
    end
  end

  describe '#access' do
    subject { described_class.for(boundary).access }

    where(:boundary, :result) do
      ref(:group)      | :selected_memberships
      ref(:project)    | :selected_memberships
      ref(:user)       | :personal_projects
      :all_memberships | :all_memberships
      :user            | :user
      :instance        | :instance
    end

    with_them do
      it { is_expected.to be(result) }
    end
  end
end
