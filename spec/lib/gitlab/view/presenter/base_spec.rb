require 'spec_helper'

describe Gitlab::View::Presenter::Base do
  let(:project) { double(:project) }
  let(:presenter_class) do
    Struct.new(:subject).include(described_class)
  end

  subject do
    presenter_class.new(project)
  end

  describe '.presents' do
    it 'exposes #subject with the given keyword' do
      presenter_class.presents(:foo)

      expect(subject.foo).to eq(project)
    end
  end

  describe '#can?' do
    let(:project) { create(:empty_project) }

    context 'user is not allowed' do
      it 'returns false' do
        expect(subject.can?(nil, :read_project)).to be_falsy
      end
    end

    context 'user is allowed' do
      let(:project) { create(:empty_project, :public) }

      it 'returns true' do
        expect(subject.can?(nil, :read_project)).to be_truthy
      end
    end
  end
end
