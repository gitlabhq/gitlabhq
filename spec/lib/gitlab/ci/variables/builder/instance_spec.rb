# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Variables::Builder::Instance do
  let_it_be(:variable1) { create(:ci_instance_variable, protected: false) }
  let_it_be(:variable2) { create(:ci_instance_variable, protected: false) }
  let_it_be(:protected_variable) { create(:ci_instance_variable, protected: true) }

  let(:builder) { described_class.new }

  describe '#secret_variables' do
    let(:variable_item1) { item(variable1) }
    let(:variable_item2) { item(variable2) }
    let(:protected_variable_item) { item(protected_variable) }
    let(:only) { nil }

    subject do
      builder.secret_variables(protected_ref: protected_ref, only: only)
    end

    context 'when the ref is protected' do
      let(:protected_ref) { true }

      it 'contains all the variables' do
        is_expected.to contain_exactly(variable_item1, variable_item2, protected_variable_item)
      end
    end

    context 'when the ref is not protected' do
      let(:protected_ref) { false }

      it 'contains only unprotected variables' do
        is_expected.to contain_exactly(variable_item1, variable_item2)
      end
    end

    context 'when only is provided' do
      let(:protected_ref) { true }
      let(:only) { [variable1.key] }

      it 'contains only requested variables' do
        is_expected.to contain_exactly(variable_item1)
      end
    end
  end

  def item(variable)
    Gitlab::Ci::Variables::Collection::Item.fabricate(variable)
  end
end
