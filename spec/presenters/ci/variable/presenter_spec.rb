require 'spec_helper'

describe Ci::Variable::Presenter do
  let(:variable) { double(:variable) }

  subject do
    described_class.new(variable)
  end

  it 'inherits from Gitlab::View::Presenter::Simple' do
    expect(described_class.superclass).to eq(Gitlab::View::Presenter::Simple)
  end

  describe '#initialize' do
    it 'takes a variable and optional params' do
      expect { subject }.not_to raise_error
    end

    it 'exposes variable' do
      expect(subject.variable).to eq(variable)
    end
  end
end
