# frozen_string_literal: true
require 'spec_helper'
require 'rubygems/package'

RSpec.describe Packages::Rubygems::MetadataExtractionService do
  include RubygemsHelpers

  let_it_be(:package) { create(:rubygems_package) }
  let_it_be(:package_file) { create(:package_file, :gem) }
  let_it_be(:gem) { gem_from_file(package_file.file) }
  let_it_be(:gemspec) { gem.spec }

  let(:service) { described_class.new(package, gemspec) }

  describe '#execute' do
    subject { service.execute }

    it 'creates the metadata' do
      expect { subject }.to change { Packages::Rubygems::Metadatum.count }.by(1)
    end

    it 'stores the metadata', :aggregate_failures do
      subject

      metadata = package.rubygems_metadatum

      expect(metadata.authors).to eq(gemspec.authors.to_json)
      expect(metadata.files).to eq(gemspec.files.to_json)
      expect(metadata.summary).to eq(gemspec.summary)
      expect(metadata.description).to eq(gemspec.description)
      expect(metadata.email).to eq(gemspec.email)
      expect(metadata.homepage).to eq(gemspec.homepage)
      expect(metadata.licenses).to eq(gemspec.licenses.to_json)
      expect(metadata.metadata).to eq(gemspec.metadata.to_json)
      expect(metadata.author).to eq(gemspec.author)
      expect(metadata.bindir).to eq(gemspec.bindir)
      expect(metadata.executables).to eq(gemspec.executables.to_json)
      expect(metadata.extensions).to eq(gemspec.extensions.to_json)
      expect(metadata.extra_rdoc_files).to eq(gemspec.extra_rdoc_files.to_json)
      expect(metadata.platform).to eq(gemspec.platform)
      expect(metadata.post_install_message).to eq(gemspec.post_install_message)
      expect(metadata.rdoc_options).to eq(gemspec.rdoc_options.to_json)
      expect(metadata.require_paths).to eq(gemspec.require_paths.to_json)
      expect(metadata.required_ruby_version).to eq(gemspec.required_ruby_version.to_s)
      expect(metadata.required_rubygems_version).to eq(gemspec.required_rubygems_version.to_s)
      expect(metadata.requirements).to eq(gemspec.requirements.to_json)
      expect(metadata.rubygems_version).to eq(gemspec.rubygems_version)
    end
  end
end
