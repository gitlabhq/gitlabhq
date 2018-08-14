require 'spec_helper'

describe Forever do
  describe '.date' do
    subject { described_class.date }

    context 'when using PostgreSQL' do
      it 'should return Postgresql future date' do
        allow(Gitlab::Database).to receive(:postgresql?).and_return(true)
        expect(subject).to eq(described_class::POSTGRESQL_DATE)
      end
    end

    context 'when using MySQL' do
      it 'should return MySQL future date' do
        allow(Gitlab::Database).to receive(:postgresql?).and_return(false)
        expect(subject).to eq(described_class::MYSQL_DATE)
      end
    end
  end
end
