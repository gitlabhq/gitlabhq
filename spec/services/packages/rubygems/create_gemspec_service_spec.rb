# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Rubygems::CreateGemspecService, feature_category: :package_registry do
  include RubygemsHelpers

  let_it_be(:package_file) { create(:package_file, :gem) }
  let_it_be(:gem) { gem_from_file(package_file.file) }
  let_it_be(:gemspec) { gem.spec }
  let_it_be(:package) { package_file.package }

  let(:service) { described_class.new(package, gemspec) }

  describe '#execute' do
    subject { service.execute }

    let(:expected_file_name) { "#{gemspec.name}-#{gemspec.version}.gemspec.rz" }
    let(:gemspec_file) { package.package_files.find_by(file_name: expected_file_name) }

    it 'creates a new package file with .rz extension', :aggregate_failures do
      expect { subject }.to change { package.package_files.count }.by(1)

      expect(gemspec_file).to have_attributes(
        file: be_present,
        size: be_present,
        file_md5: be_present,
        file_sha1: be_present,
        file_sha256: be_present,
        file_name: expected_file_name,
        project_id: package.project_id
      )
    end

    it 'creates a valid compressed Marshal format' do
      subject

      gemspec_file.file.use_file do |file_path|
        content = File.binread(file_path)
        decompressed = Zlib::Inflate.inflate(content)
        restored_gemspec = Marshal.load(decompressed) # rubocop:disable Security/MarshalLoad -- test data

        expect(restored_gemspec).to be_a(Gem::Specification)
        expect(restored_gemspec.name).to eq(gemspec.name)
        expect(restored_gemspec.version).to eq(gemspec.version)
      end
    end

    context 'with FIPS mode', :fips_mode do
      it 'does not generate file_md5' do
        expect { subject }.to change { package.package_files.count }.by(1)

        expect(gemspec_file).to have_attributes(
          file: be_present,
          size: be_present,
          file_md5: be_nil,
          file_sha1: be_present,
          file_sha256: be_present,
          project_id: package.project_id
        )
      end
    end
  end
end
