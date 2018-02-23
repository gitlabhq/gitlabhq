require 'spec_helper'

describe Gitlab::Ci::Pipeline::Expression::Parser do
  describe '#tree' do
    context 'when using operators' do
      it 'returns a reverse descent parse tree' do
        expect(described_class.seed('$VAR1 == "123" == $VAR2').tree)
          .to be_a Gitlab::Ci::Pipeline::Expression::Equals
      end
    end

    context 'when using a single token' do
      it 'returns a single token instance' do
        expect(described_class.seed('$VAR').tree)
          .to be_a Gitlab::Ci::Pipeline::Expression::Variable
      end
    end

    context 'when expression is empty' do
      it 'returns a null token' do
        expect(described_class.seed('').tree)
          .to be_a Gitlab::Ci::Pipeline::Expression::Null
      end
    end
  end
end
