# frozen_string_literal: true

require 'fast_spec_helper'

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
      expect(subject.errors.first).to eq('unknown input name provided: `nonexistent` in `inputs.nonexistent`')
    end
  end

  context 'when an expression contains an existing key followed by a non-existent key' do
    let(:access) { 'inputs.data.extra' }

    it 'returns an error' do
      expect(subject).not_to be_valid
      expect(subject.errors.first).to eq('unknown input name provided: `extra` in `inputs.data.extra`')
    end
  end
end
