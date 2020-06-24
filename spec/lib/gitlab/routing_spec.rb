# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Routing do
  context 'when module is included' do
    subject do
      Class.new.include(described_class).new
    end

    it 'makes it possible to access url helpers' do
      expect(subject).to respond_to(:namespace_project_path)
    end
  end

  context 'when module is not included' do
    subject do
      Class.new.include(described_class.url_helpers).new
    end

    it 'exposes url helpers module through a method' do
      expect(subject).to respond_to(:namespace_project_path)
    end
  end

  describe Gitlab::Routing::LegacyRedirector do
    subject { described_class.new(:wikis) }

    let(:request) { double(:request, path: path, query_string: '') }
    let(:path) { '/gitlab-org/gitlab-test/wikis/home' }

    it 'returns "-" scoped url' do
      expect(subject.call({}, request)).to eq('/gitlab-org/gitlab-test/-/wikis/home')
    end

    context 'invalid uri characters' do
      let(:path) { '/gitlab-org/gitlab-test/wikis/home[' }

      it 'raises error' do
        expect do
          subject.call({}, request)
        end.to raise_error(ActionController::RoutingError)
      end
    end
  end
end
