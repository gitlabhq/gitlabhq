require 'spec_helper'

describe Gitlab::View::Presenter do
  let(:project) { double(:project, bar: 'baz!') }
  let(:presenter) do
    base_presenter = described_class

    Class.new do
      include base_presenter

      presents :foo
    end
  end
  subject do
    presenter.new.with_subject(project)
  end

  describe '#initialize' do
    it 'takes an object accessible via a reader' do
      expect(subject.foo).to eq(project)
    end
  end

  describe 'common helpers' do
    it 'responds to #can?' do
      expect(subject).to respond_to(:can?)
    end
  end
end
