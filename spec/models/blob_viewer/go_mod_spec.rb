# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobViewer::GoMod do
  include FakeBlobHelpers

  let(:project) { build_stubbed(:project) }
  let(:data) do
    <<-SPEC.strip_heredoc
      module #{Settings.build_gitlab_go_url}/#{project.full_path}
    SPEC
  end

  let(:blob) { fake_blob(path: 'go.mod', data: data) }

  subject { described_class.new(blob) }

  describe '#package_name' do
    it 'returns the package name' do
      expect(subject.package_name).to eq("#{Settings.build_gitlab_go_url}/#{project.full_path}")
    end
  end

  describe '#package_url' do
    it 'returns the package URL' do
      expect(subject.package_url).to eq("#{Gitlab.config.gitlab.protocol}://#{Settings.build_gitlab_go_url}/#{project.full_path}/")
    end

    context 'when the homepage has an invalid URL' do
      let(:data) do
        <<-SPEC.strip_heredoc
          module javascript:alert()
        SPEC
      end

      it 'returns nil' do
        expect(subject.package_url).to be_nil
      end
    end
  end

  describe '#package_type' do
    it 'returns "package"' do
      expect(subject.package_type).to eq('go')
    end
  end

  context 'when the module name does not start with the instance URL' do
    let(:data) do
      <<-SPEC.strip_heredoc
        module example.com/foo/bar
      SPEC
    end

    subject { described_class.new(blob) }

    describe '#package_url' do
      it 'returns the pkg.go.dev URL' do
        expect(subject.package_url).to eq("https://pkg.go.dev/example.com/foo/bar")
      end
    end
  end
end
