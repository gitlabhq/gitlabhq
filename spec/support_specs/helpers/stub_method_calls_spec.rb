# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../support/helpers/stub_method_calls'

RSpec.describe StubMethodCalls do
  include described_class

  let(:object) do
    Class.new do
      def self.test_method
        'test'
      end

      def self.test_method_two(response: nil)
        response || 'test_two'
      end
    end
  end

  describe '#stub_method' do
    let(:method_to_stub) { :test_method }

    it 'stubs the method response' do
      stub_method(object, method_to_stub) { true }

      expect(object.send(method_to_stub)).to eq(true)
    end

    context 'when calling it on an already stubbed method' do
      before do
        stub_method(object, method_to_stub) { false }
      end

      it 'stubs correctly' do
        stub_method(object, method_to_stub) { true }

        expect(object.send(method_to_stub)).to eq(true)
      end
    end

    context 'methods that accept arguments' do
      it 'stubs correctly' do
        stub_method(object, method_to_stub) { |a, b| a + b }

        expect(object.send(method_to_stub, 1, 2)).to eq(3)
      end

      context 'methods that use named arguments' do
        let(:method_to_stub) { :test_method_two }

        it 'stubs correctly' do
          stub_method(object, method_to_stub) { |a: 'test'| a }

          expect(object.send(method_to_stub, a: 'testing')).to eq('testing')
          expect(object.send(method_to_stub)).to eq('test')
        end

        context 'stubbing non-existent method' do
          let(:method_to_stub) { :another_method }

          it 'stubs correctly' do
            stub_method(object, method_to_stub) { |a: 'test'| a }

            expect(object.send(method_to_stub, a: 'testing')).to eq('testing')
            expect(object.send(method_to_stub)).to eq('test')
          end
        end
      end
    end
  end

  describe '#restore_original_method' do
    before do
      stub_method(object, :test_method) { true }
    end

    it 'restores original behaviour' do
      expect(object.test_method).to eq(true)

      restore_original_method(object, :test_method)

      expect(object.test_method).to eq('test')
    end

    context 'method is not stubbed' do
      specify do
        expect do
          restore_original_method(object, 'some_other_method')
        end.to raise_error(NotImplementedError, "some_other_method has not been stubbed on #{object}")
      end
    end
  end

  describe '#restore_original_methods' do
    before do
      stub_method(object, :test_method) { true }
      stub_method(object, :test_method_two) { true }
    end

    it 'restores original behaviour' do
      restore_original_methods(object)

      expect(object.test_method).to eq('test')
      expect(object.test_method_two).to eq('test_two')
    end
  end
end
