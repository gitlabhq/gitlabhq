# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Source, feature_category: :shared do
  include StubVersion

  describe '.ref' do
    subject(:ref) { described_class.ref }

    context 'when not on a pre-release' do
      before do
        stub_version('15.0.0-ee', 'a123a123')
      end

      it { is_expected.to eq('v15.0.0-ee') }
    end

    context 'when on a pre-release' do
      before do
        stub_version('15.0.0-pre', 'a123a123')
      end

      it { is_expected.to eq('a123a123') }
    end
  end

  describe '.release_url' do
    subject(:release_url) { described_class.release_url }

    context 'when not on a pre-release' do
      before do
        stub_version('15.0.0-ee', 'a123a123')
      end

      it 'returns a tag url' do
        expect(release_url).to match("https://gitlab.com/gitlab-org/gitlab(-foss)?/-/tags/v15.0.0-ee")
      end
    end

    context 'when on a pre-release' do
      before do
        stub_version('15.0.0-pre', 'a123a123')
      end

      it 'returns a commit url' do
        expect(release_url).to match("https://gitlab.com/gitlab-org/gitlab(-foss)?/-/commits/a123a123")
      end
    end
  end
end
