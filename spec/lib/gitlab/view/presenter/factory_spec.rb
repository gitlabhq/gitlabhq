require 'spec_helper'

describe Gitlab::View::Presenter::Factory do
  let(:build) { Ci::Build.new }

  describe '#initialize' do
    context 'without optional parameters' do
      it 'takes a subject and optional params' do
        presenter = described_class.new(build)

        expect { presenter }.not_to raise_error
      end
    end

    context 'with optional parameters' do
      it 'takes a subject and optional params' do
        presenter = described_class.new(build, user: 'user')

        expect { presenter }.not_to raise_error
      end
    end
  end

  describe '#fabricate!' do
    it 'detects the presenter based on the given subject' do
      presenter = described_class.new(build).fabricate!

      expect(presenter).to be_a(Ci::BuildPresenter)
    end

    it 'uses the presenter_class if given on #initialize' do
      MyCustomPresenter = Class.new(described_class)

      presenter = described_class.new(build, presenter_class: MyCustomPresenter).fabricate!

      expect(presenter).to be_a(MyCustomPresenter)
    end
  end
end
