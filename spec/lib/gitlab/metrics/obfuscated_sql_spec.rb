require 'spec_helper'

describe Gitlab::Metrics::ObfuscatedSQL do
  describe '#to_s' do
    describe 'using single values' do
      it 'replaces a single integer' do
        sql = described_class.new('SELECT x FROM y WHERE a = 10')

        expect(sql.to_s).to eq('SELECT x FROM y WHERE a = ?')
      end

      it 'replaces a single float' do
        sql = described_class.new('SELECT x FROM y WHERE a = 10.5')

        expect(sql.to_s).to eq('SELECT x FROM y WHERE a = ?')
      end

      it 'replaces a single quoted string' do
        sql = described_class.new("SELECT x FROM y WHERE a = 'foo'")

        expect(sql.to_s).to eq('SELECT x FROM y WHERE a = ?')
      end

      if Gitlab::Database.mysql?
        it 'replaces a double quoted string' do
          sql = described_class.new('SELECT x FROM y WHERE a = "foo"')

          expect(sql.to_s).to eq('SELECT x FROM y WHERE a = ?')
        end
      end

      it 'replaces a single regular expression' do
        sql = described_class.new('SELECT x FROM y WHERE a = /foo/')

        expect(sql.to_s).to eq('SELECT x FROM y WHERE a = ?')
      end

      it 'replaces regular expressions using escaped slashes' do
        sql = described_class.new('SELECT x FROM y WHERE a = /foo\/bar/')

        expect(sql.to_s).to eq('SELECT x FROM y WHERE a = ?')
      end
    end

    describe 'using consecutive values' do
      it 'replaces multiple integers' do
        sql = described_class.new('SELECT x FROM y WHERE z IN (10, 20, 30)')

        expect(sql.to_s).to eq('SELECT x FROM y WHERE z IN (3 values)')
      end

      it 'replaces multiple floats' do
        sql = described_class.new('SELECT x FROM y WHERE z IN (1.5, 2.5, 3.5)')

        expect(sql.to_s).to eq('SELECT x FROM y WHERE z IN (3 values)')
      end

      it 'replaces multiple single quoted strings' do
        sql = described_class.new("SELECT x FROM y WHERE z IN ('foo', 'bar')")

        expect(sql.to_s).to eq('SELECT x FROM y WHERE z IN (2 values)')
      end

      if Gitlab::Database.mysql?
        it 'replaces multiple double quoted strings' do
          sql = described_class.new('SELECT x FROM y WHERE z IN ("foo", "bar")')

          expect(sql.to_s).to eq('SELECT x FROM y WHERE z IN (2 values)')
        end
      end

      it 'replaces multiple regular expressions' do
        sql = described_class.new('SELECT x FROM y WHERE z IN (/foo/, /bar/)')

        expect(sql.to_s).to eq('SELECT x FROM y WHERE z IN (2 values)')
      end
    end

    if Gitlab::Database.postgresql?
      it 'replaces double quotes' do
        sql = described_class.new('SELECT "x" FROM "y"')

        expect(sql.to_s).to eq('SELECT x FROM y')
      end
    end
  end
end
