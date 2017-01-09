require 'spec_helper'

describe Gitlab::View::Presenter::Factory do
  let(:variable) { create(:ci_variable) }

  describe '#initialize' do
    context 'without optional parameters' do
      subject do
        described_class.new(variable)
      end

      it 'takes a subject and optional params' do
        expect { subject }.not_to raise_error
      end
    end

    context 'with optional parameters' do
      subject do
        described_class.new(variable, user: 'user')
      end

      it 'takes a subject and optional params' do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe '#fabricate!' do
    subject do
      described_class.new(variable, user: 'user', foo: 'bar').fabricate!
    end

    it 'exposes given params' do
      expect(subject.user).to eq('user')
      expect(subject.foo).to eq('bar')
    end

    it 'detects the presenter based on the given subject' do
      expect(subject).to be_a(Ci::Variable::Presenter)
    end
  end
end
