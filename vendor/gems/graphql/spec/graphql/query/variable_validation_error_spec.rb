# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::VariableValidationError do
  let(:ast) { Struct.new(:name, :line, :col).new('input', 1, 2) }
  let(:type) { Struct.new(:to_type_signature).new('TestType') }
  let(:error_value) { 'some value' }
  let(:problems) { [{'path' => ['path-to-problem'], 'explanation' => 'it broke'}] }
  let(:validation_result) { Struct.new(:problems).new(problems) }
  let(:subject) do
    Class.new(GraphQL::Query::VariableValidationError) do
      def extensions
        {
          code: 'ERROR',
        }
      end
    end
  end

  describe '#to_h' do
    it 'includes value and problems in extensions' do
      error = subject.new(ast, type, error_value, validation_result)

      as_hash = {
        'message' => 'Variable $input of type TestType was provided invalid value for path-to-problem (it broke)',
        'locations' => [ {'line' => 1, 'column' => 2} ],
        'extensions' => {
          'code' => 'ERROR',
          'value' => error_value,
          'problems' => problems
        }
      }
      assert_equal error.to_h, as_hash
    end

    it 'when msg param is passed it overwrites the message and adds validation result message' do
      error = subject.new(ast, type, error_value, validation_result, msg: "test")

      as_hash = {
        'message' => 'test for path-to-problem (it broke)',
        'locations' => [ {'line' => 1, 'column' => 2} ],
        'extensions' => {
          'code' => 'ERROR',
          'value' => error_value,
          'problems' => problems
        }
      }
      assert_equal error.to_h, as_hash
    end
  end
end
