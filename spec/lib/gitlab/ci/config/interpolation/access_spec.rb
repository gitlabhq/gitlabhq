# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Access, feature_category: :pipeline_composition do
  subject { described_class.new(access, ctx) }

  let(:access) do
    'inputs.data'
  end

  let(:ctx) do
    { inputs: { data: 'abcd' }, env: { 'ENV' => 'dev' } }
  end

  it 'properly evaluates the access pattern' do
    expect(subject.value).to eq 'abcd'
  end

  context 'when there are too many objects in the access path' do
    let(:access) { 'a.b.c.d.e.f.g.h' }

    it 'only support MAX_ACCESS_OBJECTS steps' do
      expect(subject.objects.count).to eq 5
    end
  end

  context 'when access expression size is too large' do
    before do
      stub_const("#{described_class}::MAX_ACCESS_BYTESIZE", 10)
    end

    it 'returns an error' do
      expect(subject).not_to be_valid
      expect(subject.errors.first)
        .to eq 'maximum interpolation expression size exceeded'
    end
  end

  context 'when there are not enough objects in the access path' do
    let(:access) { 'abc[123]' }

    it 'returns an error when there are no objects found' do
      expect(subject).not_to be_valid
      expect(subject.errors.first)
        .to eq 'invalid pattern used for interpolation. valid pattern is $[[ inputs.input ]]'
    end
  end

  context 'when a non-existent key is accessed' do
    let(:access) { 'inputs.nonexistent' }

    it 'returns an error' do
      expect(subject).not_to be_valid
      expect(subject.errors.first).to eq('unknown interpolation provided: `nonexistent` in `inputs.nonexistent`')
    end
  end

  context 'when an expression contains an existing key followed by a non-existent key' do
    let(:access) { 'inputs.data.extra' }

    it 'returns an error' do
      expect(subject).not_to be_valid
      expect(subject.errors.first).to eq('unknown interpolation provided: `extra` in `inputs.data.extra`')
    end
  end

  context 'when accessing array by index' do
    let(:ctx) { { inputs: { my_array: %w[first second] } } }
    let(:access) { 'inputs.my_array[0]' }

    it 'returns the first element' do
      expect(subject.value).to eq 'first'
    end

    context 'when accessing a different index' do
      let(:access) { 'inputs.my_array[1]' }

      it 'returns the second element' do
        expect(subject.value).to eq 'second'
      end
    end
  end

  context 'when accessing nested value after array index' do
    let(:ctx) { { inputs: { items: [{ name: 'item1' }] } } }
    let(:access) { 'inputs.items[0].name' }

    it 'returns the nested value' do
      expect(subject.value).to eq 'item1'
    end
  end

  context 'when accessing multi-dimensional array' do
    let(:ctx) { { inputs: { matrix: [%w[a b], %w[c d]] } } }
    let(:access) { 'inputs.matrix[1][0]' }

    it 'returns the correct element' do
      expect(subject.value).to eq 'c'
    end
  end

  context 'when index is out of bounds' do
    let(:ctx) { { inputs: { arr: ['one'] } } }
    let(:access) { 'inputs.arr[1]' }

    it 'returns an error' do
      expect(subject).not_to be_valid
      expect(subject.errors.first).to eq('array index 1 out of bounds (size: 1) in `inputs.arr[1]`')
    end
  end

  context 'when indexing a non-array value' do
    let(:ctx) { { inputs: { str: 'hello' } } }
    let(:access) { 'inputs.str[0]' }

    it 'returns an error' do
      expect(subject).not_to be_valid
      expect(subject.errors.first).to include('cannot index into non-array')
    end
  end

  context 'when using negative index' do
    let(:ctx) { { inputs: { arr: %w[a b] } } }
    let(:access) { 'inputs.arr[-1]' }

    it 'returns an error for invalid pattern' do
      expect(subject).not_to be_valid
      expect(subject.errors.first).to eq('invalid array index in `inputs.arr[-1]`: `-1` is not a valid index')
    end
  end

  context 'when array element is nil' do
    let(:ctx) { { inputs: { arr: [nil, 'val'] } } }
    let(:access) { 'inputs.arr[0]' }

    it 'returns nil' do
      expect(subject.value).to be_nil
    end
  end

  context 'when array element is a hash' do
    let(:ctx) { { inputs: { rules: [{ if: '$CI', when: 'always' }] } } }
    let(:access) { 'inputs.rules[0]' }

    it 'returns the hash' do
      expect(subject.value).to eq({ if: '$CI', when: 'always' })
    end
  end

  context 'when accessing deeply nested structure with mixed arrays and hashes' do
    let(:ctx) { { inputs: { data: { items: [{ values: ['deep'] }] } } } }
    let(:access) { 'inputs.data.items[0].values[0]' }

    it 'returns the deeply nested value' do
      expect(subject.value).to eq 'deep'
    end
  end

  context 'when using non-integer index' do
    let(:ctx) { { inputs: { arr: %w[a b] } } }
    let(:access) { 'inputs.arr[a]' }

    it 'returns an error with the invalid index' do
      expect(subject).not_to be_valid
      expect(subject.errors.first).to eq('invalid array index in `inputs.arr[a]`: `a` is not a valid index')
    end
  end

  context 'when closing bracket is missing' do
    let(:ctx) { { inputs: { arr: %w[a b] } } }
    let(:access) { 'inputs.arr[0' }

    it 'returns an error about missing bracket' do
      expect(subject).not_to be_valid
      expect(subject.errors.first).to eq('invalid array index in `inputs.arr[0`: missing closing bracket')
    end
  end

  context 'when brackets are empty' do
    let(:ctx) { { inputs: { arr: %w[a b] } } }
    let(:access) { 'inputs.arr[]' }

    it 'returns an error about empty index' do
      expect(subject).not_to be_valid
      expect(subject.errors.first).to eq('invalid array index in `inputs.arr[]`: `` is not a valid index')
    end
  end

  context 'when there is trailing text after brackets' do
    let(:ctx) { { inputs: { arr: %w[a b] } } }
    let(:access) { 'inputs.arr[0]junk' }

    it 'returns an error' do
      expect(subject).not_to be_valid
      expect(subject.errors.first).to eq('invalid array index syntax in `inputs.arr[0]junk`')
    end
  end

  context 'when array index depth is at the limit' do
    let(:nested) { [[[[[42]]]]] }
    let(:ctx) { { inputs: { arr: nested } } }
    let(:access) { 'inputs.arr[0][0][0][0][0]' }

    it 'returns the value' do
      expect(subject.value).to eq 42
    end
  end

  context 'when array index depth exceeds the limit' do
    let(:nested) { [[[[[[42]]]]]] }
    let(:ctx) { { inputs: { arr: nested } } }
    let(:access) { 'inputs.arr[0][0][0][0][0][0]' }

    it 'returns an error' do
      expect(subject).not_to be_valid
      expect(subject.errors.first).to eq(
        'too many array indices in `inputs.arr[0][0][0][0][0][0]` (maximum depth: 5)'
      )
    end
  end

  context 'when an indexed segment has no base key' do
    let(:ctx) { { inputs: { matrix: [%w[a b], %w[c d]] } } }
    let(:access) { 'inputs.matrix[0].[1]' }

    it 'returns an error' do
      expect(subject).not_to be_valid
      expect(subject.errors.first).to include('invalid indexed access without a key')
    end
  end

  context 'when an indexed segment has a non-existent base key' do
    let(:ctx) { { inputs: { arr: ['val'] } } }
    let(:access) { 'inputs.nonexistent[0]' }

    it 'returns an error from the key lookup' do
      expect(subject).not_to be_valid
      expect(subject.errors.first).to eq(
        'unknown interpolation provided: `nonexistent` in `inputs.nonexistent[0]`'
      )
    end
  end
end
