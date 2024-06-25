# frozen_string_literal: true
require 'fast_spec_helper'
require 'active_support/concern'

RSpec.describe Gitlab::Utils::LazyAttributes do
  subject(:klass) do
    Class.new do
      include Gitlab::Utils::LazyAttributes

      lazy_attr_reader :number, type: Numeric
      lazy_attr_reader :reader_1, :reader_2
      lazy_attr_accessor :incorrect_type, :string_attribute, :accessor_2, type: String

      def initialize
        @number = -> { 1 }
        @reader_1 = 'reader_1'
        @reader_2 = -> { 'reader_2' }
        @incorrect_type = -> { :incorrect_type }
        @accessor_2 = -> { 'accessor_2' }
      end
    end
  end

  context 'class methods' do
    it { is_expected.to respond_to(:lazy_attr_reader, :lazy_attr_accessor) }
    it { is_expected.not_to respond_to(:define_lazy_reader, :define_lazy_writer) }
  end

  context 'instance methods' do
    subject(:instance) { klass.new }

    it do
      is_expected.to respond_to(:number, :reader_1, :reader_2, :incorrect_type,
        :incorrect_type=, :accessor_2, :accessor_2=,
        :string_attribute, :string_attribute=)
    end

    context 'reading attributes' do
      it 'returns the correct values for procs', :aggregate_failures do
        expect(instance.number).to eq(1)
        expect(instance.reader_2).to eq('reader_2')
        expect(instance.accessor_2).to eq('accessor_2')
      end

      it 'does not return the value if the type did not match what was specified' do
        expect(instance.incorrect_type).to be_nil
      end

      it 'only calls the block once even if it returned `nil`', :aggregate_failures do
        expect(instance.instance_variable_get(:@number)).to receive(:call).once.and_call_original
        expect(instance.instance_variable_get(:@accessor_2)).to receive(:call).once.and_call_original
        expect(instance.instance_variable_get(:@incorrect_type)).to receive(:call).once.and_call_original

        2.times do
          instance.number
          instance.incorrect_type
          instance.accessor_2
        end
      end
    end

    context 'writing attributes' do
      it 'sets the correct values', :aggregate_failures do
        instance.string_attribute = -> { 'updated 1' }
        instance.accessor_2 = nil

        expect(instance.string_attribute).to eq('updated 1')
        expect(instance.accessor_2).to be_nil
      end
    end
  end
end
