# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::VariableValue, feature_category: :ci_variables do
  let_it_be(:expected_value) { 'Secret value' }

  subject(:service) { described_class.new(variable) }

  shared_examples 'not hidden variable' do
    it 'returns an original value' do
      expect(service.evaluate).to eq(expected_value)
    end
  end

  shared_examples 'hidden variable' do
    it 'returns an original value' do
      expect(service.evaluate).to be_nil
    end
  end

  describe '#evaluate' do
    context 'when variable is a project variable' do
      let_it_be(:project) { create(:project) }
      let(:variable) { build(:ci_variable, project: project, value: expected_value, hidden: is_hidden) }

      context 'and it is not hidden' do
        let(:is_hidden) { false }

        it_behaves_like 'not hidden variable'
      end

      context 'and it is hidden' do
        let(:is_hidden) { true }

        it_behaves_like 'hidden variable'
      end
    end

    context 'when variable is a group variable' do
      let_it_be(:group) { create(:group) }
      let(:variable) { build(:ci_group_variable, group: group, value: expected_value, hidden: is_hidden) }

      context 'and it is not hidden' do
        let(:is_hidden) { false }

        it_behaves_like 'not hidden variable'
      end

      context 'and it is hidden' do
        let(:is_hidden) { true }

        it_behaves_like 'hidden variable'
      end
    end
  end
end
