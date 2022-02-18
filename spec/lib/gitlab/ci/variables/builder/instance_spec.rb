# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Variables::Builder::Instance do
  let_it_be(:variable) { create(:ci_instance_variable, protected: false) }
  let_it_be(:protected_variable) { create(:ci_instance_variable, protected: true) }

  let(:builder) { described_class.new }

  describe '#secret_variables' do
    let(:variable_item) { item(variable) }
    let(:protected_variable_item) { item(protected_variable) }

    subject do
      builder.secret_variables(protected_ref: protected_ref)
    end

    context 'when the ref is protected' do
      let(:protected_ref) { true }

      it 'contains all the variables' do
        is_expected.to contain_exactly(variable_item, protected_variable_item)
      end
    end

    context 'when the ref is not protected' do
      let(:protected_ref) { false }

      it 'contains only unprotected variables' do
        is_expected.to contain_exactly(variable_item)
      end
    end
  end

  def item(variable)
    Gitlab::Ci::Variables::Collection::Item.fabricate(variable)
  end
end
