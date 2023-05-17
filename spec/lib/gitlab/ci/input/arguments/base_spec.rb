# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Input::Arguments::Base, feature_category: :pipeline_composition do
  subject do
    Class.new(described_class) do
      def validate!; end
      def to_value; end
    end
  end

  it 'fabricates an invalid input argument if unknown value is provided' do
    argument = subject.new(:something, { spec: 123 }, [:a, :b])

    expect(argument).not_to be_valid
    expect(argument.errors.first).to eq 'unsupported value in input argument `something`'
  end
end
