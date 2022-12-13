# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerNamespace do
  it_behaves_like 'includes Limitable concern' do
    subject { build(:ci_runner_namespace, group: create(:group, :nested), runner: create(:ci_runner, :group)) }
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:ci_runner_namespace) }

    let!(:parent) { model.namespace }
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
