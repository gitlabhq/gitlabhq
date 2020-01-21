# frozen_string_literal: true

require 'spec_helper'

describe BlobViewer::Gemspec do
  include FakeBlobHelpers

  let(:project) { build_stubbed(:project) }
  let(:data) do
    <<-SPEC.strip_heredoc
      Gem::Specification.new do |s|
        s.platform    = Gem::Platform::RUBY
        s.name        = "activerecord"
      end
    SPEC
  end
  let(:blob) { fake_blob(path: 'activerecord.gemspec', data: data) }

  subject { described_class.new(blob) }

  describe '#package_name' do
    it 'returns the package name' do
      expect(subject).to receive(:prepare!)

      expect(subject.package_name).to eq('activerecord')
    end
  end
end
