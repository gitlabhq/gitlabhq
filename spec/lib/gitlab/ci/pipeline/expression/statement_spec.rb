require 'spec_helper'

describe Gitlab::Ci::Pipeline::Expression::Statement do
  subject do
    described_class.new(text, variables)
  end

  let(:variables) do
    { 'PRESENT_VARIABLE' => 'my variable',
      EMPTY_VARIABLE: '' }
  end

  describe '.new' do
    context 'when variables are not provided' do
      it 'allows to properly initializes the statement' do
        statement = described_class.new('$PRESENT_VARIABLE')

        expect(statement.evaluate).to be_nil
      end
    end
  end

  describe '#parse_tree' do
    context 'when expression is empty' do
      let(:text) { '' }

      it 'raises an error' do
        expect { subject.parse_tree }
          .to raise_error described_class::StatementError
      end
    end

    context 'when expression grammar is incorrect' do
      table = [
        '$VAR "text"',   # missing operator
        '== "123"',      # invalid left side
        '"some string"', # only string provided
        '$VAR ==',       # invalid right side
        '12345',         # unknown syntax
        ''               # empty statement
      ]

      table.each do |syntax|
        context "when expression grammar is #{syntax.inspect}" do
          let(:text) { syntax }

          it 'aises a statement error exception' do
            expect { subject.parse_tree }
              .to raise_error described_class::StatementError
          end

          it 'is an invalid statement' do
            expect(subject).not_to be_valid
          end
        end
      end
    end

    context 'when expression grammar is correct' do
      context 'when using an operator' do
        let(:text) { '$VAR == "value"' }

        it 'returns a reverse descent parse tree' do
          expect(subject.parse_tree)
            .to be_a Gitlab::Ci::Pipeline::Expression::Lexeme::Equals
        end

        it 'is a valid statement' do
          expect(subject).to be_valid
        end
      end

      context 'when using a single token' do
        let(:text) { '$PRESENT_VARIABLE' }

        it 'returns a single token instance' do
          expect(subject.parse_tree)
            .to be_a Gitlab::Ci::Pipeline::Expression::Lexeme::Variable
        end
      end
    end
  end

  describe '#evaluate' do
    statements = [
      ['$PRESENT_VARIABLE == "my variable"', true],
      ["$PRESENT_VARIABLE == 'my variable'", true],
      ['"my variable" == $PRESENT_VARIABLE', true],
      ['$PRESENT_VARIABLE == null', false],
      ['$EMPTY_VARIABLE == null', false],
      ['"" == $EMPTY_VARIABLE', true],
      ['$EMPTY_VARIABLE', ''],
      ['$UNDEFINED_VARIABLE == null', true],
      ['null == $UNDEFINED_VARIABLE', true],
      ['$PRESENT_VARIABLE', 'my variable'],
      ['$UNDEFINED_VARIABLE', nil]
    ]

    statements.each do |expression, value|
      context "when using expression `#{expression}`" do
        let(:text) { expression }

        it "evaluates to `#{value.inspect}`" do
          expect(subject.evaluate).to eq value
        end
      end
    end
  end

  describe '#truthful?' do
    statements = [
      ['$PRESENT_VARIABLE == "my variable"', true],
      ["$PRESENT_VARIABLE == 'no match'", false],
      ['$UNDEFINED_VARIABLE == null', true],
      ['$PRESENT_VARIABLE', true],
      ['$UNDEFINED_VARIABLE', false],
      ['$EMPTY_VARIABLE', false]
    ]

    statements.each do |expression, value|
      context "when using expression `#{expression}`" do
        let(:text) { expression }

        it "returns `#{value.inspect}`" do
          expect(subject.truthful?).to eq value
        end
      end
    end
  end
end
