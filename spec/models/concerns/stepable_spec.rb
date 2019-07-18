# frozen_string_literal: true

require 'spec_helper'

describe Stepable do
  let(:described_class) do
    Class.new do
      include Stepable

      steps :method1, :method2, :method3

      def execute
        execute_steps
      end

      private

      def method1
        { status: :success }
      end

      def method2
        return { status: :error } unless @pass

        { status: :success, variable1: 'var1' }
      end

      def method3
        { status: :success, variable2: 'var2' }
      end
    end
  end

  let(:prepended_module) do
    Module.new do
      extend ActiveSupport::Concern

      prepended do
        steps :appended_method1
      end

      private

      def appended_method1
        { status: :success }
      end
    end
  end

  before do
    described_class.prepend(prepended_module)
  end

  it 'stops after the first error' do
    expect(subject).not_to receive(:method3)
    expect(subject).not_to receive(:appended_method1)

    expect(subject.execute).to eq(
      status: :error,
      failed_step: :method2
    )
  end

  context 'when all methods return success' do
    before do
      subject.instance_variable_set(:@pass, true)
    end

    it 'calls all methods in order' do
      expect(subject).to receive(:method1).and_call_original.ordered
      expect(subject).to receive(:method2).and_call_original.ordered
      expect(subject).to receive(:method3).and_call_original.ordered
      expect(subject).to receive(:appended_method1).and_call_original.ordered

      subject.execute
    end

    it 'merges variables returned by all steps' do
      expect(subject.execute).to eq(
        status: :success,
        variable1: 'var1',
        variable2: 'var2'
      )
    end
  end

  context 'with multiple stepable classes' do
    let(:other_class) do
      Class.new do
        include Stepable

        steps :other_method1, :other_method2

        private

        def other_method1
          { status: :success }
        end

        def other_method2
          { status: :success }
        end
      end
    end

    it 'does not leak steps' do
      expect(other_class.new.steps).to contain_exactly(:other_method1, :other_method2)
      expect(subject.steps).to contain_exactly(:method1, :method2, :method3, :appended_method1)
    end
  end
end
