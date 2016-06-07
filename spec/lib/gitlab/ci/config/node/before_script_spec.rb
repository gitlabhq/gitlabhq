require 'spec_helper'

describe Gitlab::Ci::Config::Node::BeforeScript do
  let(:entry) { described_class.new(value, double)}
  before { entry.validate! }

  context 'when entry value is correct' do
    let(:value) { ['ls', 'pwd'] }

    describe '#script' do
      it 'returns concatenated command' do
        expect(entry.script).to eq "ls\npwd"
      end
    end

    describe '#errors' do
      it 'does not append errors' do
        expect(entry.errors).to be_empty
      end
    end
  end

  context 'when entry value is not correct' do
    let(:value) { 'ls' }

    describe '#errors' do
      it 'saves errors' do
        expect(entry.errors)
          .to include /should be an array of strings/
      end
    end

    describe '#script' do
      it 'raises error' do
        expect { entry.script }.to raise_error
      end
    end
  end
end
