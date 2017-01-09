require 'spec_helper'

describe Gitlab::View::Presenter::Delegated do
  let(:project) { double(:project, foo: 'bar') }
  let(:presenter_class) do
    Class.new(described_class)
  end

  subject do
    presenter_class.new(project)
  end

  it 'includes Gitlab::View::Presenter::Base' do
    expect(described_class).to include(Gitlab::View::Presenter::Base)
  end

  describe '#initialize' do
    subject do
      presenter_class.new(project, user: 'user', foo: 'bar')
    end

    it 'takes arbitrary key/values and exposes them' do
      expect(subject.user).to eq('user')
      expect(subject.foo).to eq('bar')
    end
  end

  describe 'delegation' do
    it 'does not forward missing methods to subject' do
      expect(subject.foo).to eq('bar')
    end
  end
end
