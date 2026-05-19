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

  describe '#visible_to?' do
    let_it_be(:other_user) { create(:user) }
    let_it_be(:external_user) { create(:user, external: true) }
    let_it_be(:private_group) { create(:group, :private) }
    let_it_be(:internal_group) { create(:group, :internal) }
    let_it_be(:public_group) { create(:group, :public) }
    let_it_be(:private_project) { create(:project, :private, group: private_group) }
    let_it_be(:internal_project) { create(:project, :internal) }
    let_it_be(:public_project) { create(:project, :public) }

    subject { described_class.for(boundary).visible_to?(visibility_user) }

    where(:boundary, :visibility_user, :result) do
      ref(:private_group)    | ref(:other_user)    | false
      ref(:private_group)    | nil                 | false
      ref(:private_group)    | ref(:external_user) | false
      ref(:internal_group)   | ref(:other_user)    | true
      ref(:internal_group)   | nil                 | false
      ref(:internal_group)   | ref(:external_user) | false
      ref(:public_group)     | ref(:other_user)    | true
      ref(:public_group)     | nil                 | true
      ref(:public_group)     | ref(:external_user) | true
      ref(:private_project)  | ref(:other_user)    | false
      ref(:private_project)  | ref(:external_user) | false
      ref(:internal_project) | ref(:other_user)    | true
      ref(:internal_project) | ref(:external_user) | false
      ref(:public_project)   | nil                 | true
      ref(:public_project)   | ref(:external_user) | true
      ref(:user)             | ref(:other_user)    | true
      :all_memberships       | ref(:other_user)    | true
      :user                  | ref(:other_user)    | true
      :instance              | ref(:other_user)    | true
    end

    with_them do
      it { is_expected.to be(result) }
    end

    context 'when the user is an admin', :enable_admin_mode do
      let_it_be(:admin) { create(:admin) }

      it 'is visible regardless of visibility level' do
        expect(described_class.for(private_group).visible_to?(admin)).to be(true)
        expect(described_class.for(private_project).visible_to?(admin)).to be(true)
      end
    end
  end

  describe '#type_label' do
    subject { described_class.for(boundary).type_label }

    where(:boundary, :result) do
      ref(:group)      | 'group'
      ref(:project)    | 'project'
      ref(:user)       | 'personal projects'
      :all_memberships | 'all memberships'
      :user            | 'user'
      :instance        | 'instance'
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end
end
