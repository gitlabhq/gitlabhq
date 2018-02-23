require 'spec_helper'

describe Gitlab::Ci::Pipeline::Expression::Statement do
  let(:pipeline) { build(:ci_pipeline) }
  let(:text) { '$VAR "text"' }

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
      let(:text) { '$VAR "text"' }

      it 'raises an error' do
        expect { subject.parse_tree }
          .to raise_error described_class::StatementError
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
end
