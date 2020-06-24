# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Expression::Token do
  let(:value) { '$VARIABLE' }
  let(:lexeme) { Gitlab::Ci::Pipeline::Expression::Lexeme::Variable }

  subject { described_class.new(value, lexeme) }

  describe '#value' do
    it 'returns raw token value' do
      expect(subject.value).to eq value
    end
  end

  describe '#lexeme' do
    it 'returns raw token lexeme' do
      expect(subject.lexeme).to eq lexeme
    end
  end

  describe '#build' do
    it 'delegates to lexeme after adding a value' do
      expect(lexeme).to receive(:build)
        .with(value, 'some', 'args')

      subject.build('some', 'args')
    end

    it 'allows passing only required arguments' do
      expect(subject.build).to be_an_instance_of(lexeme)
    end
  end

  describe '#type' do
    it 'delegates type query to the lexeme' do
      expect(subject.type).to eq :value
    end
  end

  describe '#to_lexeme' do
    it 'returns raw lexeme syntax component name' do
      expect(subject.to_lexeme).to eq 'variable'
    end
  end
end
