# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Rubygems::CreateSpecFilesService, feature_category: :package_registry do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:other_project) { create(:project) }
  let_it_be(:package) do
    create(:rubygems_package, :with_metadatum, project: project, name: 'my_gem', version: '1.0.0')
  end

  let_it_be(:older_package) do
    create(:rubygems_package, :with_metadatum, project: project, name: 'my_gem', version: '0.9.0')
  end

  let_it_be(:newer_package) do
    create(:rubygems_package, :with_metadatum, project: project, name: 'my_gem', version: '2.0.0')
  end

  let_it_be(:prerelease_package) do
    create(:rubygems_package, :with_metadatum, project: project, name: 'my_gem', version: '2.1.0.pre')
  end

  let_it_be(:other_project_package) do
    create(:rubygems_package, :with_metadatum, project: other_project, name: 'other_gem', version: '3.0.0')
  end

  let_it_be(:pending_destruction_package) do
    create(:rubygems_package, :with_metadatum, project: project, name: 'old_gem', version: '1.0.0',
      status: :pending_destruction)
  end

  let(:lease_key) { "packages:rubygems:create_spec_files_service:#{project.id}" }
  let(:service) { described_class.new(project) }
  let(:released_specs) do
    [
      [older_package.name, Gem::Version.new(older_package.version), older_package.rubygems_metadatum.platform],
      [package.name, Gem::Version.new(package.version), package.rubygems_metadatum.platform],
      [newer_package.name, Gem::Version.new(newer_package.version), newer_package.rubygems_metadatum.platform]
    ]
  end

  let(:latest_specs) do
    [[newer_package.name, Gem::Version.new(newer_package.version), newer_package.rubygems_metadatum.platform]]
  end

  let(:prerelease_specs) do
    [
      [
        prerelease_package.name,
        Gem::Version.new(prerelease_package.version),
        prerelease_package.rubygems_metadatum.platform
      ]
    ]
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    it 'creates the RubyGems spec files', :aggregate_failures do
      response = nil

      expect { response = execute }.to change { Packages::Rubygems::SpecFile.count }.by(3)

      expect(response).to be_success
    end

    it 'generates all three spec files with the correct contents', :aggregate_failures do
      response = execute

      expect(response).to be_success

      released_set = read_spec_file('specs.4.8.gz')

      expect(released_set).to match_array(released_specs)
      expect(read_spec_file('latest_specs.4.8.gz')).to match_array(latest_specs)
      expect(read_spec_file('prerelease_specs.4.8.gz')).to match_array(prerelease_specs)

      expect(released_set).not_to include(
        [other_project_package.name, Gem::Version.new(other_project_package.version), 'ruby']
      )
      expect(released_set).not_to include(
        [pending_destruction_package.name, Gem::Version.new(pending_destruction_package.version), 'ruby']
      )

      expect(released_set).to eq(
        released_set.sort_by { |name, version, platform| [name, version, platform.to_s] }
      )
    end

    context 'when the project has no installable rubygems packages' do
      let_it_be(:empty_project) { create(:project) }
      let(:service) { described_class.new(empty_project) }

      it 'creates three empty spec files', :aggregate_failures do
        expect { execute }.to change { Packages::Rubygems::SpecFile.count }.by(3)

        %w[specs.4.8.gz latest_specs.4.8.gz prerelease_specs.4.8.gz].each do |file_name|
          expect(read_spec_file(file_name, empty_project)).to eq([])
        end
      end
    end

    context 'with existing spec files' do
      let_it_be(:spec_file) { create(:rubygems_spec_file, project: project, file_name: 'specs.4.8.gz') }
      let_it_be(:latest_spec_file) { create(:rubygems_spec_file, project: project, file_name: 'latest_specs.4.8.gz') }
      let_it_be(:prerelease_spec_file) do
        create(:rubygems_spec_file, project: project, file_name: 'prerelease_specs.4.8.gz')
      end

      it 'updates the existing files', :aggregate_failures do
        expect { execute }.to not_change { Packages::Rubygems::SpecFile.count }

        expect(read_spec_file('specs.4.8.gz')).to match_array(released_specs)
        expect(read_spec_file('latest_specs.4.8.gz')).to match_array(latest_specs)
        expect(read_spec_file('prerelease_specs.4.8.gz')).to match_array(prerelease_specs)
      end
    end

    context 'when saving the spec file fails' do
      let(:spec_file) { Packages::Rubygems::SpecFile.new }

      before do
        allow(Packages::Rubygems::SpecFile).to receive(:find_or_build).and_return(spec_file)
        allow(spec_file).to receive(:update!).and_raise(error)
      end

      context 'with a record invalid error' do
        let(:error) { ActiveRecord::RecordInvalid.new(spec_file) }

        it 'returns an error response' do
          expect(execute).to be_error
        end
      end

      context 'with a record not unique error' do
        let(:error) { ActiveRecord::RecordNotUnique.new('duplicate key') }

        it 'returns an error response' do
          expect(execute).to be_error
        end
      end
    end

    it 'obtains a lease to create the spec files' do
      expect_to_obtain_exclusive_lease(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)

      execute
    end

    context 'when the lease is already taken' do
      before do
        stub_exclusive_lease_taken(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)
      end

      it 'does not create spec files' do
        expect { execute }.to not_change { Packages::Rubygems::SpecFile.count }
      end

      it 'returns a success response' do
        expect(execute).to be_success
      end
    end
  end

  describe '#lease_key' do
    subject { service.send(:lease_key) }

    it 'returns a unique key' do
      is_expected.to eq(lease_key)
    end
  end

  def read_spec_file(file_name, project_to_read = project)
    spec_file = Packages::Rubygems::SpecFile.find_by!(project: project_to_read, file_name: file_name)

    Zlib::GzipReader.wrap(StringIO.new(spec_file.file.read)) do |gzip|
      Marshal.load(gzip.read) # rubocop:disable Security/MarshalLoad -- RubyGems spec indexes are Marshal dumps and this test reads trusted generated content.
    end
  end
end
