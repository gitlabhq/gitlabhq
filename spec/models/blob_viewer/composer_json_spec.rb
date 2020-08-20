# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobViewer::ComposerJson do
  include FakeBlobHelpers

  let(:project) { build_stubbed(:project) }
  let(:data) do
    <<-SPEC.strip_heredoc
      {
        "name": "laravel/laravel",
        "homepage": "https://laravel.com/"
      }
    SPEC
  end

  let(:blob) { fake_blob(path: 'composer.json', data: data) }

  subject { described_class.new(blob) }

  describe '#package_name' do
    it 'returns the package name' do
      expect(subject).to receive(:prepare!)

      expect(subject.package_name).to eq('laravel/laravel')
    end
  end
end
