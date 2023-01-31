# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Debian::ExtractDebMetadataService, feature_category: :package_registry do
  subject { described_class.new(file_path) }

  let(:file_name) { 'libsample0_1.2.3~alpha2_amd64.deb' }
  let(:file_path) { "spec/fixtures/packages/debian/#{file_name}" }

  context 'with correct file' do
    it 'return as expected' do
      expected = {
        'Package' => 'libsample0',
        'Source' => 'sample',
        'Version' => '1.2.3~alpha2',
        'Architecture' => 'amd64',
        'Maintainer' => 'John Doe <john.doe@example.com>',
        'Installed-Size' => '7',
        'Section' => 'libs',
        'Priority' => 'optional',
        'Multi-Arch' => 'same',
        'Homepage' => 'https://gitlab.com/',
        'Description' => "Some mostly empty lib\nUsed in GitLab tests.\n\nTesting another paragraph."
      }

      expect(subject.execute).to eq expected
    end
  end

  context 'with incorrect file' do
    let(:file_name) { 'README.md' }

    it 'raise error' do
      expect { subject.execute }.to raise_error(described_class::CommandFailedError, /is not a Debian format archive/i)
    end
  end
end
