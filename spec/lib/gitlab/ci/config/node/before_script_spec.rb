require 'spec_helper'

describe Gitlab::Ci::Config::Node::BeforeScript do
  let(:entry) { described_class.new(value, double)}
  before { entry.validate! }

  context 'when entry value is correct' do
    let(:value) { ['ls', 'pwd'] }

    describe '#value' do
      it 'returns concatenated command' do
        expect(entry.value).to eq "ls\npwd"
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
  end
end
