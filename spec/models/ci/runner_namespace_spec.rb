# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerNamespace, feature_category: :runner do
  it_behaves_like 'includes Limitable concern' do
    let_it_be(:group) { create(:group, :nested) }
    let_it_be(:another_group) { create(:group) }
    let_it_be(:runner) { create(:ci_runner, :group, groups: [another_group]) }

    subject { build(:ci_runner_namespace, namespace: group, runner: runner) }
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:parent) { create(:group) }
    let!(:runner) { create(:ci_runner, :group, groups: [parent]) }
    let(:model) { runner.runner_namespaces.first }
  end

  describe 'validations' do
    let_it_be(:runner) { create(:ci_runner, :group, groups: [create(:group)]) }

    it { is_expected.to validate_presence_of(:namespace).on([:create, :update]) }
    it { is_expected.to validate_uniqueness_of(:runner_id).scoped_to(:namespace_id) }

    it 'validates that runner_id is valid' do
      runner_namespace = runner.runner_namespaces.first
      runner_namespace.runner_id = nil
      expect(runner_namespace).not_to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:runner) }
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:group).class_name('::Group').with_foreign_key(:namespace_id) }
  end

  describe '.for_runner' do
    subject(:for_runner) { described_class.for_runner(runner_ids) }

    let_it_be(:group) { create(:group) }
    let_it_be(:runners) { create_list(:ci_runner, 3, :group, groups: [group]) }

    context 'with runner ids' do
      let(:runner_ids) { runners[1..2].map(&:id) }

      it 'returns requested runner namespaces' do
        is_expected.to eq(runners[1..2].flat_map(&:runner_namespaces))
      end
    end

    context 'with runners' do
      let(:runner_ids) { runners.first }

      it 'returns requested runner namespaces' do
        is_expected.to eq(runners.first.runner_namespaces)
      end
    end
  end
end
