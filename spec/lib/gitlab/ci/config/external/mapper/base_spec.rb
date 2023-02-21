# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Mapper::Base, feature_category: :pipeline_composition do
  let(:test_class) do
    Class.new(described_class) do
      def self.name
        'TestClass'
      end
    end
  end

  let(:context) { Gitlab::Ci::Config::External::Context.new }
  let(:mapper) { test_class.new(context) }

  describe '#process' do
    subject(:process) { mapper.process }

    context 'when the method is not implemented' do
      it 'raises NotImplementedError' do
        expect { process }.to raise_error(NotImplementedError)
      end
    end

    context 'when the method is implemented' do
      before do
        test_class.class_eval do
          def process_without_instrumentation
            'test'
          end
        end
      end

      it 'calls the method' do
        expect(process).to eq('test')
      end
    end
  end
end
