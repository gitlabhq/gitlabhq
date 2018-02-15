require 'spec_helper'

describe Gitlab::Database::Median do
  describe '#extract_medians' do
    context 'when using MySQL' do
      it 'returns an empty hash' do
        values = [["1", "1000"]]

        allow(Gitlab::Database).to receive(:mysql?).and_return(true)

        expect(described_class.new.extract_median(values)).eq({})
      end
    end
  end
end
