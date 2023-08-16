# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Inputs, feature_category: :pipeline_composition do
  let(:inputs) { described_class.new(specs, args) }
  let(:specs) { { foo: { default: 'bar' } } }
  let(:args) { {} }

  context 'when inputs are valid' do
    where(:specs, :args, :merged) do
      [
        [
          { foo: { default: 'bar' } }, {},
          { foo: 'bar' }
        ],
        [
          { foo: { default: 'bar' } }, { foo: 'test' },
          { foo: 'test' }
        ],
        [
          { foo: nil }, { foo: 'bar' },
          { foo: 'bar' }
        ],
        [
          { foo: { type: 'string' } }, { foo: 'bar' },
          { foo: 'bar' }
        ],
        [
          { foo: { type: 'string', default: 'bar' } }, { foo: 'test' },
          { foo: 'test' }
        ],
        [
          { foo: { type: 'string', default: 'bar' } }, {},
          { foo: 'bar' }
        ],
        [
          { foo: { default: 'bar' }, baz: nil }, { baz: 'test' },
          { foo: 'bar', baz: 'test' }
        ],
        [
          { number_input: { type: 'number' } },
          { number_input: 8 },
          { number_input: 8 }
        ],
        [
          { default_number_input: { default: 9, type: 'number' } },
          {},
          { default_number_input: 9 }
        ],
        [
          { true_input: { type: 'boolean' }, false_input: { type: 'boolean' } },
          { true_input: true, false_input: false },
          { true_input: true, false_input: false }
        ],
        [
          { default_boolean_input: { default: true, type: 'boolean' } },
          {},
          { default_boolean_input: true }
        ]
      ]
    end

    with_them do
      it 'contains the merged inputs' do
        expect(inputs).to be_valid
        expect(inputs.to_hash).to eq(merged)
      end
    end
  end

  context 'when inputs are invalid' do
    where(:specs, :args, :errors) do
      [
        [
          { foo: nil }, { foo: 'bar', test: 'bar' },
          ['unknown input arguments: test']
        ],
        [
          { foo: nil }, { test: 'bar', gitlab: '1' },
          ['unknown input arguments: test, gitlab', '`foo` input: required value has not been provided']
        ],
        [
          { foo: 123 }, {},
          ['unknown input specification for `foo` (valid types: boolean, number, string)']
        ],
        [
          { a: nil, foo: 123 }, { a: '123' },
          ['unknown input specification for `foo` (valid types: boolean, number, string)']
        ],
        [
          { foo: nil }, {},
          ['`foo` input: required value has not been provided']
        ],
        [
          { foo: { default: 123 } }, { foo: 'test' },
          ['`foo` input: default value is not a string']
        ],
        [
          { foo: { default: 'test' } }, { foo: 123 },
          ['`foo` input: provided value is not a string']
        ],
        [
          { foo: nil }, { foo: 123 },
          ['`foo` input: provided value is not a string']
        ],
        [
          { number_input: { type: 'number' } },
          { number_input: 'NaN' },
          ['`number_input` input: provided value is not a number']
        ],
        [
          { default_number_input: { default: 'NaN', type: 'number' } },
          {},
          ['`default_number_input` input: default value is not a number']
        ],
        [
          { boolean_input: { type: 'boolean' } },
          { boolean_input: 'string' },
          ['`boolean_input` input: provided value is not a boolean']
        ],
        [
          { default_boolean_input: { default: 'string', type: 'boolean' } },
          {},
          ['`default_boolean_input` input: default value is not a boolean']
        ]
      ]
    end

    with_them do
      it 'contains the merged inputs', :aggregate_failures do
        expect(inputs).not_to be_valid
        expect(inputs.errors).to contain_exactly(*errors)
      end
    end
  end
end
