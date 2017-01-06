require 'spec_helper'

describe VariablePresenter do
  let(:variable) { double(:variable, foo: 'bar') }
  subject do
    described_class.new.with_subject(variable)
  end

  describe '#initialize' do
    it 'takes a variable and optional params' do
      expect { subject }.
        not_to raise_error
    end

    it 'exposes variable' do
      expect(subject.variable).to eq(variable)
    end

    it 'does not forward missing methods to variable' do
      expect { subject.foo }.to raise_error(NoMethodError)
    end
  end
end
