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

    let(:gemspec_file) { package.package_files.find_by(file_name: "#{gemspec.name}.gemspec") }

    it 'creates a new package file', :aggregate_failures do
      expect { subject }.to change { package.package_files.count }.by(1)

      expect(gemspec_file).to have_attributes(
        file: be_present,
        size: be_present,
        file_md5: be_present,
        file_sha1: be_present,
        file_sha256: be_present,
        project_id: package.project_id
      )
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
