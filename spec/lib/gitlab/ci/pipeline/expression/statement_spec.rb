require 'spec_helper'

describe Gitlab::Ci::Pipeline::Expression::Statement do
  let(:pipeline) { build(:ci_pipeline) }

  subject do
    described_class.new(text, pipeline)
  end

  before do
    pipeline.variables.build([key: 'VARIABLE', value: 'my variable'])
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
        '$VAR "text"',      # missing operator
        '== "123"',         # invalid right side
        "'single quotes'",  # single quotes string
        '$VAR ==',          # invalid right side
        '12345',            # unknown syntax
        ''                  # empty statement
      ]

      table.each do |syntax|
        it "raises an error when syntax is `#{syntax}`" do
          expect { described_class.new(syntax, pipeline).parse_tree }
            .to raise_error described_class::StatementError
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
      end

      context 'when using a single token' do
        let(:text) { '$VARIABLE' }

        it 'returns a single token instance' do
          expect(subject.parse_tree)
            .to be_a Gitlab::Ci::Pipeline::Expression::Lexeme::Variable
        end
      end
    end
  end

  describe '#evaluate' do
    statements = [
      ['$VARIABLE == "my variable"', true],
      ["$VARIABLE == 'my variable'", true],
      ['"my variable" == $VARIABLE', true],
      ['$VARIABLE == null', false],
      ['$VAR == null', true],
      ['null == $VAR', true],
      ['$VARIABLE', 'my variable'],
      ['$VAR', nil]
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
end
