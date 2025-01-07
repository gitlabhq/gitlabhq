# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Lazy do
  def load(key)
    BatchLoader.for(key).batch do |keys, loader|
      keys.each { |x| loader.call(x, x * x) }
    end
  end

  let(:value) { double(x: 1) }

  describe '#force' do
    subject { described_class.new { value.x } }

    it 'can extract the value' do
      expect(subject.force).to be 1
    end

    it 'can derive new lazy values' do
      expect(subject.then { |x| x + 2 }.force).to be 3
    end

    it 'only evaluates once' do
      expect(value).to receive(:x).once

      expect(subject.force).to eq(subject.force)
    end

    it 'deals with nested laziness' do
      expect(described_class.new { load(10) }.force).to eq(100)
      expect(described_class.new { described_class.new { 5 } }.force).to eq 5
    end
  end

  describe '.with_value' do
    let(:inner) { described_class.new { value.x } }

    subject { described_class.with_value(inner) { |x| x.to_s } }

    it 'defers the application of a block to a value' do
      expect(value).not_to receive(:x)

      expect(subject).to be_an_instance_of(described_class)
    end

    it 'evaluates to the application of the block to the value' do
      expect(value).to receive(:x).once

      expect(subject.force).to eq(inner.force.to_s)
    end
  end

  describe '.force' do
    context 'when given a plain value' do
      subject { described_class.force(1) }

      it 'unwraps the value' do
        expect(subject).to be 1
      end
    end

    context 'when given a wrapped lazy value' do
      subject { described_class.force(described_class.new { 2 }) }

      it 'unwraps the value' do
        expect(subject).to be 2
      end
    end

    context 'when the value is from a batchloader' do
      subject { described_class.force(load(3)) }

      it 'syncs the value' do
        expect(subject).to be 9
      end
    end

    context 'when the value is a GraphQL lazy' do
      subject { described_class.force(GitlabSchema.after_lazy(load(3)) { |x| x + 1 }) }

      it 'forces the evaluation' do
        expect(subject).to be 10
      end
    end

    context 'when the value is a promise' do
      subject { described_class.force(::Concurrent::Promise.new { 4 }) }

      it 'executes the promise and waits for the value' do
        expect(subject).to be 4
      end
    end
  end
end
