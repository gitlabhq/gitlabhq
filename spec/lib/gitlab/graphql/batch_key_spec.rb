# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ::Gitlab::Graphql::BatchKey do
  let(:rect) { Struct.new(:len, :width) }
  let(:circle) { Struct.new(:radius) }
  let(:lookahead) { nil }
  let(:object) { rect.new(2, 3) }

  subject { described_class.new(object, lookahead, object_name: :rect) }

  it 'is equal to keys of the same object, regardless of lookahead or object name' do
    expect(subject).to eq(described_class.new(rect.new(2, 3)))
    expect(subject).to eq(described_class.new(rect.new(2, 3), :anything))
    expect(subject).to eq(described_class.new(rect.new(2, 3), lookahead, object_name: :does_not_matter))
    expect(subject).not_to eq(described_class.new(rect.new(2, 4)))
    expect(subject).not_to eq(described_class.new(circle.new(10)))
  end

  it 'delegates attribute lookup methods to the inner object' do
    other = rect.new(2, 3)

    expect(subject.hash).to eq(other.hash)
    expect(subject.len).to eq(other.len)
    expect(subject.width).to eq(other.width)
  end

  it 'allows the object to be named more meaningfully' do
    expect(subject.object).to eq(object)
    expect(subject.object).to eq(subject.rect)
  end

  it 'works as a hash key' do
    h = { subject => :foo }

    expect(h[described_class.new(object)]).to eq(:foo)
  end

  describe '#requires?' do
    it 'returns false if the lookahead was not provided' do
      expect(subject.requires?([:foo])).to be(false)
    end

    context 'lookahead was provided' do
      let(:lookahead) { double(:Lookahead) }

      before do
        allow(lookahead).to receive(:selection).with(Symbol).and_return(lookahead)
      end

      it 'returns false if the path is empty' do
        expect(subject.requires?([])).to be(false)
      end

      context 'it selects the field' do
        before do
          allow(lookahead).to receive(:selects?).with(Symbol).once.and_return(true)
        end

        it 'returns true' do
          expect(subject.requires?(%i[foo bar baz])).to be(true)
        end
      end

      context 'it does not select the field' do
        before do
          allow(lookahead).to receive(:selects?).with(Symbol).once.and_return(false)
        end

        it 'returns false' do
          expect(subject.requires?(%i[foo bar baz])).to be(false)
        end
      end
    end
  end
end
