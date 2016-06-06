require 'spec_helper'

describe Gitlab::Ci::Config::Node::BeforeScript do
  let(:entry) { described_class.new(value, config) }
  let(:config) { double('config') }

  describe '#validate!' do
    before { entry.validate! }

    context 'when entry value is correct' do
      let(:value) { ['ls', 'pwd'] }

      it 'does not append errors' do
        expect(entry.errors).to be_empty
      end
    end

    context 'when entry value is not correct' do
      let(:value) { 'ls' }

      it 'saves errors' do
        expect(entry.errors)
          .to include /should be an array of strings/
      end
    end
  end
end
