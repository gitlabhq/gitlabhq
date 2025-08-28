# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authz::GranularScope, feature_category: :permissions do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).required }
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    describe 'permissions' do
      using RSpec::Parameterized::TableSyntax

      where(:permissions, :valid) do
        nil              | false
        'create_issue'   | false
        []               | false
        %w[xxx]          | false
        %w[create_issue] | true
      end

      with_them do
        subject { build(:granular_scope, permissions:).valid? }

        it { is_expected.to eq(valid) }
      end
    end
  end

  describe '#boundary' do
    subject { build(:granular_scope, namespace:).boundary }

    context 'when namespace is a group' do
      let(:namespace) { build(:group) }

      it { is_expected.to eq('Group') }
    end

    context 'when namespace is a project namespace' do
      let(:namespace) { build(:project_namespace) }

      it { is_expected.to eq('Project') }
    end

    context 'when namespace is a user namespace' do
      let(:namespace) { build(:user_namespace) }

      it { is_expected.to eq('User') }
    end

    context 'when namespace is nil' do
      let(:namespace) { nil }

      it { is_expected.to eq('Instance') }
    end
  end
end
