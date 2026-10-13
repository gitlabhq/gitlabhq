# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authz::Boundary, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:group) { create(:group, developers: user) }
  let_it_be(:project) { create(:project, namespace: group) }

  describe '.declarative_policy_class' do
    subject(:declarative_policy_class) { described_class::Base.declarative_policy_class }

    it { expect(declarative_policy_class).to eq('Authz::BoundaryPolicy') }
  end

  describe '.for' do
    subject(:strategy) { described_class.for(boundary) }

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
      it { expect(strategy).to be_a(result) }
    end
  end

  describe '.strategy_for_type' do
    subject(:strategy_for_type) { described_class.strategy_for_type(type) }

    where(:type, :result) do
      :project  | described_class::ProjectBoundary
      :group    | described_class::GroupBoundary
      :user     | nil
      nil       | nil
    end

    with_them do
      it { expect(strategy_for_type).to eq(result) }
    end
  end

  describe '.record_class' do
    subject(:record_class) { strategy.record_class }

    where(:strategy, :result) do
      described_class::ProjectBoundary | ::Project
      described_class::GroupBoundary   | ::Group
    end

    with_them do
      it { expect(record_class).to eq(result) }
    end
  end

  describe '.namespace_association' do
    subject(:namespace_association) { strategy.namespace_association }

    where(:strategy, :result) do
      described_class::ProjectBoundary | :project_namespace
      described_class::GroupBoundary   | nil
    end

    with_them do
      it { expect(namespace_association).to eq(result) }
    end
  end

  describe '#root_namespace_id' do
    subject(:root_namespace_id) { described_class.for(boundary).root_namespace_id }

    where(:boundary, :result) do
      ref(:group)   | lazy { group.id }
      ref(:project) | lazy { group.id }
      :instance     | nil
    end

    with_them do
      it { expect(root_namespace_id).to eq(result) }
    end
  end

  describe '#namespace' do
    subject(:namespace) { described_class.for(boundary).namespace }

    where(:boundary, :result) do
      ref(:group)      | ref(:group)
      ref(:project)    | lazy { project.project_namespace }
      ref(:user)       | lazy { user.namespace }
      :all_memberships | nil
      :user            | nil
      :instance        | nil
    end

    with_them do
      it { expect(namespace).to eq(result) }
    end
  end

  describe '#path' do
    subject(:path) { described_class.for(boundary).path }

    where(:boundary, :result) do
      ref(:group)      | lazy { group.full_path }
      ref(:project)    | lazy { project.project_namespace.full_path }
      ref(:user)       | lazy { user.namespace.full_path }
      :all_memberships | nil
      :user            | nil
      :instance        | nil
    end

    with_them do
      it { expect(path).to eq(result) }
    end

    context 'when a user boundary has no namespace' do
      let(:user) { create(:user) }
      let(:boundary) { user }

      it { expect(path).to be_nil }
    end
  end

  describe '#access' do
    subject(:access) { described_class.for(boundary).access }

    where(:boundary, :result) do
      ref(:group)      | :selected_memberships
      ref(:project)    | :selected_memberships
      ref(:user)       | :personal_projects
      :all_memberships | :all_memberships
      :user            | :user
      :instance        | :instance
    end

    with_them do
      it { expect(access).to be(result) }
    end
  end

  describe '#type_label' do
    subject(:type_label) { described_class.for(boundary).type_label }

    where(:boundary, :result) do
      ref(:group)      | 'group'
      ref(:project)    | 'project'
      ref(:user)       | 'personal projects'
      :all_memberships | 'all memberships'
      :user            | 'user'
      :instance        | 'instance'
    end

    with_them do
      it { expect(type_label).to eq(result) }
    end
  end
end
