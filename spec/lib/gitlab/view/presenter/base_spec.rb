# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::View::Presenter::Base do
  let(:project) { double(:project) }
  let(:presenter_class) do
    Struct.new(:subject).include(described_class)
  end

  describe '.presenter?' do
    it 'returns true' do
      presenter = presenter_class.new(project)

      expect(presenter.class).to be_presenter
    end
  end

  describe '.presents' do
    it 'exposes #subject with the given keyword' do
      presenter_class.presents(:foo)
      presenter = presenter_class.new(project)

      expect(presenter.foo).to eq(project)
    end
  end

  describe '#can?' do
    context 'user is not allowed' do
      it 'returns false' do
        presenter = presenter_class.new(build_stubbed(:project))

        expect(presenter.can?(nil, :read_project)).to be_falsy
      end
    end

    context 'user is allowed' do
      it 'returns true' do
        presenter = presenter_class.new(build_stubbed(:project, :public))

        expect(presenter.can?(nil, :read_project)).to be_truthy
      end
    end

    context 'subject is overridden' do
      it 'returns true' do
        presenter = presenter_class.new(build_stubbed(:project, :public))

        expect(presenter.can?(nil, :read_project, build_stubbed(:project))).to be_falsy
      end
    end
  end

  describe '#present' do
    it 'returns self' do
      presenter = presenter_class.new(build_stubbed(:project))
      expect(presenter.present).to eq(presenter)
    end
  end

  describe '#url_builder' do
    it 'returns the UrlBuilder instance' do
      presenter = presenter_class.new(project)

      expect(presenter.url_builder).to eq(Gitlab::UrlBuilder.instance)
    end
  end

  describe '#web_url' do
    it 'delegates to the UrlBuilder' do
      presenter = presenter_class.new(project)

      expect(presenter.url_builder).to receive(:build).with(project)

      presenter.web_url
    end
  end

  describe '#web_path' do
    it 'delegates to the UrlBuilder' do
      presenter = presenter_class.new(project)

      expect(presenter.url_builder).to receive(:build).with(project, only_path: true)

      presenter.web_path
    end
  end
end
