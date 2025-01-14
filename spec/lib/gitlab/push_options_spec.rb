# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::PushOptions do
  describe 'namespace and key validation' do
    it 'ignores unrecognised namespaces' do
      options = described_class.new(['invalid.key=value'])

      expect(options.get(:invalid)).to eq(nil)
    end

    it 'ignores unrecognised keys' do
      options = described_class.new(['merge_request.key=value'])

      expect(options.get(:merge_request)).to eq(nil)
    end

    it 'ignores blank keys' do
      options = described_class.new(['merge_request'])

      expect(options.get(:merge_request)).to eq(nil)
    end

    it 'parses recognised namespace and key pairs' do
      options = described_class.new(['merge_request.target=value'])

      expect(options.get(:merge_request)).to include({
        target: 'value'
      })
    end

    it 'protects against malicious backtracking' do
      option = "#{'=' * 1_000_000}."

      expect do
        Timeout.timeout(10.seconds) do
          described_class.new([option])
        end
      end.not_to raise_error
    end
  end

  describe '#get' do
    it 'can emulate Hash#dig' do
      options = described_class.new(['merge_request.target=value'])

      expect(options.get(:merge_request, :target)).to eq('value')
    end
  end

  describe '#as_json' do
    it 'returns all options as a JSON serializable Hash' do
      options = described_class.new(['merge_request.target=value'])

      expect(options.as_json).to include('merge_request' => { 'target' => 'value' })
      expect(options.as_json).not_to include(merge_request: { target: 'value' })
    end
  end

  it 'can parse multiple push options' do
    options = described_class.new(
      [
        'merge_request.create',
        'merge_request.target=value'
      ])

    expect(options.get(:merge_request)).to include({
      create: true,
      target: 'value'
    })
    expect(options.get(:merge_request, :create)).to eq(true)
    expect(options.get(:merge_request, :target)).to eq('value')
  end

  it 'stores options internally as a HashWithIndifferentAccess' do
    options = described_class.new(
      [
        'merge_request.create'
      ])

    expect(options.get('merge_request', 'create')).to eq(true)
    expect(options.get(:merge_request, :create)).to eq(true)
  end

  it 'selects the last option when options contain duplicate namespace and key pairs' do
    options = described_class.new(
      [
        'merge_request.target=value1',
        'merge_request.target=value2'
      ])

    expect(options.get(:merge_request, :target)).to eq('value2')
  end

  it 'defaults values to true' do
    options = described_class.new(['merge_request.create'])

    expect(options.get(:merge_request, :create)).to eq(true)
  end

  it 'expands aliases' do
    options = described_class.new(['mr.target=value'])

    expect(options.get(:merge_request, :target)).to eq('value')
  end

  it 'forgives broken push options' do
    options = described_class.new(['merge_request . target = value'])

    expect(options.get(:merge_request, :target)).to eq('value')
  end
end
