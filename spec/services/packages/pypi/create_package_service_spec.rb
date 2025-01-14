# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Pypi::CreatePackageService, :aggregate_failures, feature_category: :package_registry do
  include PackagesManagerApiSpecHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }

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

  let(:expected_package_attrs) { { name: params[:name], version: params[:version] } }
  let(:expected_pypi_metadata) { { required_python: params[:requires_python] } }
  let(:expected_package_file_attrs) do
    {
      file_name: params[:content].original_filename,
      file_sha256: params[:sha256_digest],
      file_md5: params[:md5_digest]
    }
  end

  subject(:service_response) { described_class.new(project, user, params).execute }

  shared_examples 'a success response for valid package' do
    it_behaves_like 'returning a success service response'

    it 'creates the package' do
      expect { subject }.to change { Packages::Package.pypi.count }.by(1)
                        .and change { Packages::PackageFile.count }.by(1)
                        .and change { Packages::Pypi::Metadatum.count }.by(1)

      expect(created_package).to have_attributes(expected_package_attrs)
      expect(created_package.pypi_metadatum).to have_attributes(expected_pypi_metadata)
      expect(created_package.package_files.size).to eq 1
      expect(created_package.package_files.first).to have_attributes(expected_package_file_attrs)
    end
  end

  shared_examples 'an error response while not creating a pypi package' do |message:, reason:|
    it_behaves_like 'returning an error service response', message: message
    it { is_expected.to have_attributes(reason: reason) }

    it 'does not create any pypi-related package records' do
      expect { service_response }
        .to not_change { Packages::Package.count }
        .and not_change { Packages::Package.pypi.count }
        .and not_change { Packages::PackageFile.count }
    end
  end

  describe '#execute' do
    let(:created_package) { Packages::Package.pypi.last }

    it_behaves_like 'a success response for valid package'

    it_behaves_like 'assigns the package creator' do
      let(:package) { created_package }
    end

    it_behaves_like 'assigns build to package' do
      let(:subject) { super().payload.fetch(:package) }
    end

    it_behaves_like 'assigns status to package' do
      let(:subject) { super().payload.fetch(:package) }
    end

    context 'with FIPS mode', :fips_mode do
      let(:expected_package_file_attrs) { super().merge(file_md5: nil) }

      it_behaves_like 'a success response for valid package'
    end

    context 'without required_python' do
      let(:params) { super().except(:requires_python) }
      let(:expected_pypi_metadata) { { required_python: '' } }

      it_behaves_like 'a success response for valid package'
    end

    context 'with additional metadata' do
      let(:params) { super().merge(additional_metadata) }
      let(:expected_pypi_metadata) { additional_metadata }
      let(:additional_metadata) do
        {
          metadata_version: '2.3',
          author_email: 'cschultz@example.com, snoopy@peanuts.com',
          description: 'Example description',
          description_content_type: 'text/plain',
          summary: 'A module for collecting votes from beagles.',
          keywords: 'dog,puppy,voting,election'
        }
      end

      it_behaves_like 'a success response for valid package'
    end

    context 'with a very long metadata field' do
      let(:params) do
        super().merge(
          requires_python: super_long_field,
          keywords: super_long_field,
          metadata_version: super_long_field,
          description: super_long_field,
          summary: super_long_field,
          description_content_type: super_long_field,
          author_email: super_long_field
        )
      end

      let(:expected_pypi_metadata) do
        super().merge(
          required_python: super_long_field.truncate(::Packages::Pypi::Metadatum::MAX_REQUIRED_PYTHON_LENGTH),
          keywords: super_long_field.truncate(::Packages::Pypi::Metadatum::MAX_KEYWORDS_LENGTH),
          metadata_version: super_long_field.truncate(::Packages::Pypi::Metadatum::MAX_METADATA_VERSION_LENGTH),
          description: super_long_field.truncate(::Packages::Pypi::Metadatum::MAX_DESCRIPTION_LENGTH),
          summary: super_long_field.truncate(::Packages::Pypi::Metadatum::MAX_SUMMARY_LENGTH),
          description_content_type:
            super_long_field.truncate(::Packages::Pypi::Metadatum::MAX_DESCRIPTION_CONTENT_TYPE_LENGTH),
          author_email: super_long_field.truncate(::Packages::Pypi::Metadatum::MAX_AUTHOR_EMAIL_LENGTH)
        )
      end

      let(:super_long_field) { 'x' * 10000 }

      it_behaves_like 'a success response for valid package'
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

        it_behaves_like 'an error response while not creating a pypi package',
          message: 'Validation failed: File name has already been taken',
          reason: :invalid_parameter

        context 'with a pending_destruction package' do
          before do
            Packages::Package.pypi.last.pending_destruction!
          end

          it_behaves_like 'a success response for valid package'
        end
      end

      context 'without an existing file' do
        before do
          params[:content] = temp_file('another.tgz')
        end

        it 'adds the file' do
          expect { service_response }
            .to change { Packages::Package.pypi.count }.by(0)
            .and change { Packages::PackageFile.count }.by(1)

          expect(created_package.package_files.size).to eq 2
          expect(created_package.package_files.map(&:file_name).sort).to eq ['another.tgz', 'foo.tgz']
        end
      end
    end

    context 'with unauthorized user' do
      let_it_be(:user) { create(:user) }

      it_behaves_like 'an error response while not creating a pypi package',
        message: 'Unauthorized',
        reason: :unauthorized
    end

    context 'without user' do
      let_it_be(:user) { nil }

      it_behaves_like 'an error response while not creating a pypi package',
        message: 'Unauthorized',
        reason: :unauthorized
    end

    context 'with package protection rule for different roles and package_name_patterns' do
      let_it_be_with_reload(:package_protection_rule) do
        create(:package_protection_rule, package_type: :pypi, project: project)
      end

      let_it_be(:project_developer) { create(:user, developer_of: project) }
      let_it_be(:project_maintainer) { create(:user, maintainer_of: project) }
      let_it_be(:project_owner) { project.owner }

      let_it_be(:project_deploy_token) { create(:deploy_token, :all_scopes, projects: [project]) }
      let_it_be(:unauthorized_deploy_token) { create(:deploy_token, :all_scopes) }

      let(:package_name) { params[:name] }

      let(:package_name_pattern_no_match) { "#{package_name}_no_match" }

      let(:service) { described_class.new(project, current_user, params) }

      shared_examples 'an error response for protected package' do
        it_behaves_like 'an error response while not creating a pypi package',
          message: 'Package protected.',
          reason: :package_protected
      end

      shared_examples 'an error response for unauthorized' do
        it_behaves_like 'an error response while not creating a pypi package',
          message: 'Unauthorized',
          reason: :unauthorized
      end

      before do
        package_protection_rule.update!(package_name_pattern: package_name_pattern,
          minimum_access_level_for_push: minimum_access_level_for_push)
      end

      # rubocop:disable Layout/LineLength -- Avoid formatting to keep one-line table syntax
      where(:package_name_pattern, :minimum_access_level_for_push, :user, :shared_examples_name) do
        ref(:package_name)                  | :maintainer | ref(:project_developer)         | 'an error response for protected package'
        ref(:package_name)                  | :maintainer | ref(:project_maintainer)        | 'a success response for valid package'
        ref(:package_name)                  | :maintainer | ref(:project_owner)             | 'a success response for valid package'
        ref(:package_name)                  | :maintainer | ref(:project_deploy_token)      | 'an error response for protected package'
        ref(:package_name)                  | :owner      | ref(:project_maintainer)        | 'an error response for protected package'
        ref(:package_name)                  | :owner      | ref(:project_owner)             | 'a success response for valid package'
        ref(:package_name)                  | :owner      | ref(:project_deploy_token)      | 'an error response for protected package'
        ref(:package_name)                  | :admin      | ref(:project_owner)             | 'an error response for protected package'
        ref(:package_name)                  | :admin      | ref(:project_deploy_token)      | 'an error response for protected package'

        ref(:package_name_pattern_no_match) | :maintainer | ref(:project_owner)             | 'a success response for valid package'
        ref(:package_name_pattern_no_match) | :admin      | ref(:project_owner)             | 'a success response for valid package'
        ref(:package_name_pattern_no_match) | :admin      | ref(:project_deploy_token)      | 'a success response for valid package'

        ref(:package_name)                  | :maintainer | nil                             | 'an error response for unauthorized'
        ref(:package_name)                  | :admin      | ref(:unauthorized_deploy_token) | 'an error response for unauthorized'
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it_behaves_like params[:shared_examples_name]
      end
    end
  end
end
