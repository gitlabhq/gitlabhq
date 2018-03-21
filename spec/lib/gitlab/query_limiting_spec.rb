require 'spec_helper'

describe Gitlab::QueryLimiting do
  describe '.enable?' do
    it 'returns true in a test environment' do
      expect(described_class.enable?).to eq(true)
    end

    it 'returns true in a development environment' do
      allow(Rails.env).to receive(:development?).and_return(true)

      expect(described_class.enable?).to eq(true)
    end

    it 'returns false on GitLab.com' do
      expect(Rails.env).to receive(:development?).and_return(false)
      expect(Rails.env).to receive(:test?).and_return(false)
      allow(Gitlab).to receive(:com?).and_return(true)

      expect(described_class.enable?).to eq(false)
    end

    it 'returns false in a non GitLab.com' do
      allow(Gitlab).to receive(:com?).and_return(false)
      expect(Rails.env).to receive(:development?).and_return(false)
      expect(Rails.env).to receive(:test?).and_return(false)

      expect(described_class.enable?).to eq(false)
    end
  end

  describe '.whitelist' do
    it 'raises ArgumentError when an invalid issue URL is given' do
      expect { described_class.whitelist('foo') }
        .to raise_error(ArgumentError)
    end

    context 'without a transaction' do
      it 'does nothing' do
        expect { described_class.whitelist('https://example.com') }
          .not_to raise_error
      end
    end

    context 'with a transaction' do
      let(:transaction) { Gitlab::QueryLimiting::Transaction.new }

      before do
        allow(Gitlab::QueryLimiting::Transaction)
          .to receive(:current)
          .and_return(transaction)
      end

      it 'does not increment the number of SQL queries executed in the block' do
        before = transaction.count

        described_class.whitelist('https://example.com')

        2.times do
          User.count
        end

        expect(transaction.count).to eq(before)
      end
    end
  end
end
