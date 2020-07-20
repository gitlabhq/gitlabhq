# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::View::Presenter::Factory do
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
      my_custom_presenter = Class.new(described_class)

      presenter = described_class.new(build, presenter_class: my_custom_presenter).fabricate!

      expect(presenter).to be_a(my_custom_presenter)
    end
  end
end
