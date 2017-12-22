require 'spec_helper'

describe Gitlab::Utils::Override do
  let(:base) { Struct.new(:good) }

  let(:derived) do
    Class.new(base) do
      extend Gitlab::Utils::Override # rubocop:disable RSpec/DescribedClass
    end
  end

  shared_examples 'good derivation' do
    subject do
      derived.module_eval do
        override :good
        def good
          super.succ
        end
      end

      derived
    end
  end

  shared_examples 'bad derivation' do
    subject do
      derived.module_eval do
        override :bad
        def bad
          true
        end
      end

      derived
    end
  end

  describe '#override' do
    context 'when STATIC_VERIFICATION is set' do
      before do
        stub_env('STATIC_VERIFICATION', 'true')
      end

      it_behaves_like 'good derivation' do
        it 'checks ok for overriding method' do
          result = subject.new(0).good

          expect(result).to eq(1)
        end
      end

      it_behaves_like 'bad derivation' do
        it 'raises NotImplementedError when it is not overriding anything' do
          expect { subject }.to raise_error(NotImplementedError)
        end
      end
    end

    context 'when STATIC_VERIFICATION is not set' do
      it_behaves_like 'good derivation' do
        it 'does not complain when it is overriding anything' do
          result = subject.new(0).good

          expect(result).to eq(1)
        end
      end

      it_behaves_like 'bad derivation' do
        it 'does not complain when it is not overriding anything' do
          result = subject.new(0).bad

          expect(result).to eq(true)
        end
      end
    end
  end
end
