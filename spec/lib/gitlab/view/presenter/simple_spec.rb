require 'spec_helper'

describe Gitlab::View::Presenter::Simple do
  let(:project) { double(:project) }
  let(:presenter_class) do
    Class.new(described_class)
  end

  it 'includes Gitlab::View::Presenter::Base' do
    expect(described_class).to include(Gitlab::View::Presenter::Base)
  end

  describe '#initialize' do
    it 'takes arbitrary key/values and exposes them' do
      presenter = presenter_class.new(project, user: 'user', foo: 'bar')

      expect(presenter.user).to eq('user')
      expect(presenter.foo).to eq('bar')
    end
  end

  describe 'delegation' do
    it 'does not forward missing methods to subject' do
      presenter = presenter_class.new(project)

      expect { presenter.foo }.to raise_error(NoMethodError)
    end
  end
end
