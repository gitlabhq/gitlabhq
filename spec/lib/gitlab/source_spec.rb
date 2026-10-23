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

    def release_path
      Gitlab::Utils.append_path(
        described_class.send(:host_url),
        "#{described_class.send(:group)}/#{described_class.send(:project)}")
    end

    def stub_default_url_options(protocol: 'http', host: 'example.com', port: nil, script_name: '')
      expect(Gitlab::Application.routes).to receive(:default_url_options)
        .and_return(protocol: protocol, host: host, port: port, script_name: script_name)
    end

    context 'when a relative_url_root is configured' do
      before do
        stub_version('15.0.0-ee', 'a123a123')
        allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('/gitlab')
        stub_default_url_options(script_name: '/gitlab')
      end

      it 'strips the relative_url_root prefix from the path' do
        expect(release_url).to eq("#{release_path}/-/tags/v15.0.0-ee")
      end
    end

    context 'when not on a pre-release' do
      before do
        stub_version('15.0.0-ee', 'a123a123')
      end

      it 'returns a tag url' do
        expect(release_url).to eq("#{release_path}/-/tags/v15.0.0-ee")
      end
    end

    context 'when on a pre-release' do
      before do
        stub_version('15.0.0-pre', 'a123a123')
      end

      it 'returns a commit url' do
        expect(release_url).to eq("#{release_path}/-/commits/a123a123")
      end
    end
  end
end
