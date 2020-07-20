# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Limitable do
  let(:minimal_test_class) do
    Class.new do
      include ActiveModel::Model

      def self.name
        'TestClass'
      end

      include Limitable
    end
  end

  before do
    stub_const("MinimalTestClass", minimal_test_class)
  end

  it { expect(MinimalTestClass.limit_name).to eq('test_classes') }

  context 'with scoped limit' do
    before do
      MinimalTestClass.limit_scope = :project
    end

    it { expect(MinimalTestClass.limit_scope).to eq(:project) }

    it 'triggers scoped validations' do
      instance = MinimalTestClass.new

      expect(instance).to receive(:validate_scoped_plan_limit_not_exceeded)

      instance.valid?(:create)
    end
  end

  context 'with global limit' do
    before do
      MinimalTestClass.limit_scope = Limitable::GLOBAL_SCOPE
    end

    it { expect(MinimalTestClass.limit_scope).to eq(Limitable::GLOBAL_SCOPE) }

    it 'triggers scoped validations' do
      instance = MinimalTestClass.new

      expect(instance).to receive(:validate_global_plan_limit_not_exceeded)

      instance.valid?(:create)
    end
  end
end
