require 'spec_helper'

describe Gitlab::Ci::Build::Policy do
  let(:policy) { spy('policy specification') }

  before do
    stub_const("#{described_class}::Something", policy)
  end

  describe '.fabricate' do
    context 'when policy exists' do
      it 'fabricates and initializes relevant policy' do
        specs = described_class.fabricate(something: 'some value')

        expect(specs).to be_an Array
        expect(specs).to be_one
        expect(policy).to have_received(:new).with('some value')
      end
    end

    context 'when some policies are not defined' do
      it 'gracefully skips unknown policies' do
        expect { described_class.fabricate(unknown: 'first') }
          .to raise_error(NameError)
      end
    end

    context 'when passing a nil value as specs' do
      it 'returns an empty array' do
        specs = described_class.fabricate(nil)

        expect(specs).to be_an Array
        expect(specs).to be_empty
      end
    end
  end
end
