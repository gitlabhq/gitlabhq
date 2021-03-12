# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Graphql::CallsGitaly::FieldExtension, :request_store do
  include GraphqlHelpers

  let(:field_args) { {} }
  let(:owner) { fresh_object_type }
  let(:field) do
    ::Types::BaseField.new(name: 'value', type: GraphQL::STRING_TYPE, null: true, owner: owner, **field_args)
  end

  def resolve_value
    resolve_field(field, { value: 'foo' }, object_type: owner)
  end

  context 'when the field calls gitaly' do
    before do
      owner.define_method :value do
        Gitlab::SafeRequestStore['gitaly_call_actual'] = 1
        'fresh-from-the-gitaly-mines!'
      end
    end

    context 'when the field has a constant complexity' do
      let(:field_args) { { complexity: 100 } }

      it 'allows the call' do
        expect { resolve_value }.not_to raise_error
      end
    end

    context 'when the field declares that it calls gitaly' do
      let(:field_args) { { calls_gitaly: true } }

      it 'allows the call' do
        expect { resolve_value }.not_to raise_error
      end
    end

    context 'when the field does not have these arguments' do
      let(:field_args) { {} }

      it 'notices, and raises, mentioning the field' do
        expect { resolve_value }.to raise_error(include('Object.value'))
      end
    end
  end

  context 'when it does not call gitaly' do
    let(:field_args) { {} }

    it 'does not raise' do
      value = resolve_value

      expect(value).to eq 'foo'
    end
  end

  context 'when some field calls gitaly while we were waiting' do
    let(:extension) { described_class.new(field: field, options: {}) }

    it 'is acceptable if all are accounted for' do
      object = :anything
      arguments = :any_args

      ::Gitlab::SafeRequestStore['gitaly_call_actual'] = 3
      ::Gitlab::SafeRequestStore['graphql_gitaly_accounted_for'] = 0

      expect do |b|
        extension.resolve(object: object, arguments: arguments, &b)
      end.to yield_with_args(object, arguments, [3, 0])

      ::Gitlab::SafeRequestStore['gitaly_call_actual'] = 13
      ::Gitlab::SafeRequestStore['graphql_gitaly_accounted_for'] = 10

      expect { extension.after_resolve(value: 'foo', memo: [3, 0]) }.not_to raise_error
    end

    it 'is unacceptable if some of the calls are unaccounted for' do
      ::Gitlab::SafeRequestStore['gitaly_call_actual'] = 10
      ::Gitlab::SafeRequestStore['graphql_gitaly_accounted_for'] = 9

      expect { extension.after_resolve(value: 'foo', memo: [0, 0]) }.to raise_error(include('Object.value'))
    end
  end
end
