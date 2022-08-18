# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Expression::Lexeme::String do
  describe '.build' do
    it 'creates a new instance of the token' do
      expect(described_class.build('"my string"'))
        .to be_a(described_class)
    end
  end

  describe '.type' do
    it 'is a value lexeme' do
      expect(described_class.type).to eq :value
    end
  end

  describe '.scan' do
    context 'when using double quotes' do
      it 'correctly identifies string token' do
        scanner = StringScanner.new('"some string"')

        token = described_class.scan(scanner)

        expect(token).not_to be_nil
        expect(token.build.evaluate).to eq 'some string'
      end
    end

    context 'when using single quotes' do
      it 'correctly identifies string token' do
        scanner = StringScanner.new("'some string 2'")

        token = described_class.scan(scanner)

        expect(token).not_to be_nil
        expect(token.build.evaluate).to eq 'some string 2'
      end
    end

    context 'when there are mixed quotes in the string' do
      it 'is a greedy scanner for double quotes' do
        scanner = StringScanner.new('"some string" "and another one"')

        token = described_class.scan(scanner)

        expect(token).not_to be_nil
        expect(token.build.evaluate).to eq 'some string'
      end

      it 'is a greedy scanner for single quotes' do
        scanner = StringScanner.new("'some string' 'and another one'")

        token = described_class.scan(scanner)

        expect(token).not_to be_nil
        expect(token.build.evaluate).to eq 'some string'
      end

      it 'allows to use single quotes inside double quotes' do
        scanner = StringScanner.new(%("some ' string"))

        token = described_class.scan(scanner)

        expect(token).not_to be_nil
        expect(token.build.evaluate).to eq "some ' string"
      end

      it 'allow to use double quotes inside single quotes' do
        scanner = StringScanner.new(%('some " string'))

        token = described_class.scan(scanner)

        expect(token).not_to be_nil
        expect(token.build.evaluate).to eq 'some " string'
      end

      it 'allows to use an empty string inside single quotes' do
        scanner = StringScanner.new(%(''))

        token = described_class.scan(scanner)

        expect(token.build.evaluate).to eq ''
      end

      it 'allow to use an empty string inside double quotes' do
        scanner = StringScanner.new(%(""))

        token = described_class.scan(scanner)

        expect(token.build.evaluate).to eq ''
      end
    end
  end

  describe '#evaluate' do
    it 'returns string value if it is present' do
      string = described_class.new('my string')

      expect(string.evaluate).to eq 'my string'
    end

    it 'returns an empty string if it is empty' do
      string = described_class.new('')

      expect(string.evaluate).to eq ''
    end
  end
end
