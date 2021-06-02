# frozen_string_literal: true

require 'fast_spec_helper'
require 'active_model'

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

    context 'with custom relation' do
      before do
        MinimalTestClass.limit_relation = :custom_relation
      end

      it 'triggers custom limit_relation' do
        instance = MinimalTestClass.new

        def instance.project
          @project ||= Object.new
        end

        limits = Object.new
        custom_relation = Object.new
        expect(instance).to receive(:custom_relation).and_return(custom_relation)
        expect(instance.project).to receive(:actual_limits).and_return(limits)
        expect(limits).to receive(:exceeded?).with(instance.class.name.demodulize.tableize, custom_relation).and_return(false)

        instance.valid?(:create)
      end
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
