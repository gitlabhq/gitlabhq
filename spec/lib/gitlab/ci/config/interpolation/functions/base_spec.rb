# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Functions::Base, feature_category: :pipeline_composition do
  let(:custom_function_klass) do
    Class.new(described_class) do
      def self.function_expression_pattern
        /.*/
      end

      def self.name
        'test_function'
      end
    end
  end

  it 'defines an expected interface for child classes' do
    expect { described_class.function_expression_pattern }.to raise_error(NotImplementedError)
    expect { described_class.name }.to raise_error(NotImplementedError)
    expect { custom_function_klass.new('test', nil).execute('input') }.to raise_error(NotImplementedError)
  end
end
