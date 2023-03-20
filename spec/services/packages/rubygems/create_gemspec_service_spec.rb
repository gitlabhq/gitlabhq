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

    it 'creates a new package file', :aggregate_failures do
      expect { subject }.to change { package.package_files.count }.by(1)

      gemspec_file = package.package_files.find_by(file_name: "#{gemspec.name}.gemspec")
      expect(gemspec_file.file).not_to be_nil
      expect(gemspec_file.size).not_to be_nil
      expect(gemspec_file.file_md5).not_to be_nil
      expect(gemspec_file.file_sha1).not_to be_nil
      expect(gemspec_file.file_sha256).not_to be_nil
    end

    context 'with FIPS mode', :fips_mode do
      it 'does not generate file_md5' do
        expect { subject }.to change { package.package_files.count }.by(1)

        gemspec_file = package.package_files.find_by(file_name: "#{gemspec.name}.gemspec")
        expect(gemspec_file.file).not_to be_nil
        expect(gemspec_file.size).not_to be_nil
        expect(gemspec_file.file_md5).to be_nil
        expect(gemspec_file.file_sha1).not_to be_nil
        expect(gemspec_file.file_sha256).not_to be_nil
      end
    end
  end
end
