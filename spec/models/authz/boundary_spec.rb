# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authz::Boundary, feature_category: :permissions do
  let_it_be(:group) { build(:group) }
  let_it_be(:project) { build(:project) }
  let_it_be(:user) { build(:user, :with_namespace) }
  let_it_be(:instance) { nil }

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

    context 'when boundary is instance' do
      let(:boundary) { instance }

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

    context 'when boundary is instance' do
      let(:boundary) { instance }

      it { is_expected.to be_nil }
    end
  end
end
