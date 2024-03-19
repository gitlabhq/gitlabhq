# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Pypi::CreatePackageService, :aggregate_failures, feature_category: :package_registry do
  include PackagesManagerApiSpecHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:sha256) { '1' * 64 }
  let(:md5) { '567' }

  let(:requires_python) { '>=2.7' }
  let(:params) do
    {
      name: 'foo',
      version: '1.0',
      content: temp_file('foo.tgz'),
      requires_python: requires_python,
      sha256_digest: sha256,
      md5_digest: md5
    }
  end

  describe '#execute' do
    subject(:execute_service) { described_class.new(project, user, params).execute }

    let(:created_package) { Packages::Package.pypi.last }

    context 'without an existing package' do
      it 'creates the package' do
        expect { execute_service }.to change { Packages::Package.pypi.count }.by(1)

        expect(created_package.name).to eq 'foo'
        expect(created_package.version).to eq '1.0'

        expect(created_package.pypi_metadatum.required_python).to eq '>=2.7'
        expect(created_package.package_files.size).to eq 1
        expect(created_package.package_files.first.file_name).to eq 'foo.tgz'
        expect(created_package.package_files.first.file_sha256).to eq sha256
        expect(created_package.package_files.first.file_md5).to eq md5
      end
    end

    context 'with FIPS mode', :fips_mode do
      it 'does not generate file_md5' do
        expect { execute_service }.to change { Packages::Package.pypi.count }.by(1)

        expect(created_package.name).to eq 'foo'
        expect(created_package.version).to eq '1.0'

        expect(created_package.pypi_metadatum.required_python).to eq '>=2.7'
        expect(created_package.package_files.size).to eq 1
        expect(created_package.package_files.first.file_name).to eq 'foo.tgz'
        expect(created_package.package_files.first.file_sha256).to eq sha256
        expect(created_package.package_files.first.file_md5).to be_nil
      end
    end

    context 'without required_python' do
      before do
        params.delete(:requires_python)
      end

      it 'creates the package' do
        expect { execute_service }.to change { Packages::Package.pypi.count }.by(1)

        expect(created_package.pypi_metadatum.required_python).to eq ''
      end
    end

    context 'with additional metadata' do
      before do
        params.merge!(
          metadata_version: '2.3',
          author_email: 'cschultz@example.com, snoopy@peanuts.com',
          description: 'Example description',
          description_content_type: 'text/plain',
          summary: 'A module for collecting votes from beagles.',
          keywords: 'dog,puppy,voting,election'
        )
      end

      it 'creates the package' do
        expect { execute_service }.to change { Packages::Package.pypi.count }.by(1)

        expect(created_package.pypi_metadatum.metadata_version).to eq('2.3')
        expect(created_package.pypi_metadatum.author_email).to eq('cschultz@example.com, snoopy@peanuts.com')
        expect(created_package.pypi_metadatum.description).to eq('Example description')
        expect(created_package.pypi_metadatum.description_content_type).to eq('text/plain')
        expect(created_package.pypi_metadatum.summary).to eq('A module for collecting votes from beagles.')
        expect(created_package.pypi_metadatum.keywords).to eq('dog,puppy,voting,election')
      end
    end

    shared_examples 'saves a very long metadata field' do |field_name:, max_length:|
      let(:truncated_field) { ('x' * (max_length + 1)).truncate(max_length) }

      before do
        params.merge!(
          { field_name.to_sym => 'x' * (max_length + 1) }
        )
      end

      it 'truncates the field' do
        expect { subject }.to change { Packages::Package.pypi.count }.by(1)

        expect(created_package.pypi_metadatum.public_send(field_name)).to eq(truncated_field)
      end
    end

    it_behaves_like 'saves a very long metadata field',
      field_name: 'keywords',
      max_length: ::Packages::Pypi::Metadatum::MAX_KEYWORDS_LENGTH

    it_behaves_like 'saves a very long metadata field',
      field_name: 'description',
      max_length: ::Packages::Pypi::Metadatum::MAX_DESCRIPTION_LENGTH

    context 'with an invalid metadata' do
      let(:requires_python) { 'x' * 256 }

      it_behaves_like 'returning an error service response',
        message: 'Validation failed: Required python is too long (maximum is 255 characters)' do
        it { is_expected.to have_attributes(reason: :invalid_parameter) }
      end
    end

    it_behaves_like 'assigns the package creator' do
      let(:package) { created_package }
    end

    it_behaves_like 'assigns build to package' do
      let(:subject) { super().payload.fetch(:package) }
    end

    it_behaves_like 'assigns status to package' do
      let(:subject) { super().payload.fetch(:package) }
    end

    context 'with an existing package' do
      before do
        described_class.new(project, user, params).execute
      end

      context 'with an existing file' do
        before do
          params[:content] = temp_file('foo.tgz')
          params[:sha256_digest] = sha256
          params[:md5_digest] = md5
        end

        it_behaves_like 'returning an error service response',
          message: 'Validation failed: File name has already been taken' do
          it { is_expected.to have_attributes(reason: :invalid_parameter) }
        end

        it 'does not create a pypi package' do
          expect { execute_service }
            .to change { Packages::Package.pypi.count }.by(0)
            .and change { Packages::PackageFile.count }.by(0)
        end

        context 'with a pending_destruction package' do
          before do
            Packages::Package.pypi.last.pending_destruction!
          end

          it 'creates a new package' do
            expect { execute_service }
              .to change { Packages::Package.pypi.count }.by(1)
              .and change { Packages::PackageFile.count }.by(1)

            expect(created_package.name).to eq 'foo'
            expect(created_package.version).to eq '1.0'

            expect(created_package.pypi_metadatum.required_python).to eq '>=2.7'
            expect(created_package.package_files.size).to eq 1
            expect(created_package.package_files.first.file_name).to eq 'foo.tgz'
            expect(created_package.package_files.first.file_sha256).to eq sha256
            expect(created_package.package_files.first.file_md5).to eq md5
          end
        end
      end

      context 'without an existing file' do
        before do
          params[:content] = temp_file('another.tgz')
        end

        it 'adds the file' do
          expect { execute_service }
            .to change { Packages::Package.pypi.count }.by(0)
            .and change { Packages::PackageFile.count }.by(1)

          expect(created_package.package_files.size).to eq 2
          expect(created_package.package_files.map(&:file_name).sort).to eq ['another.tgz', 'foo.tgz']
        end
      end
    end
  end
end
