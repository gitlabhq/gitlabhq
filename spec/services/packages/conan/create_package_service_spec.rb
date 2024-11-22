# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Conan::CreatePackageService, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }

  subject(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    let(:package) { service_response.payload.fetch(:package) }

    let(:params) do
      {
        package_name: 'my-pkg',
        package_version: '1.0.0',
        package_username: ::Packages::Conan::Metadatum.package_username_from(full_path: project.full_path),
        package_channel: 'stable'
      }
    end

    subject(:service_response) { service.execute }

    shared_examples 'a service response for valid package' do
      it_behaves_like 'returning a success service response'

      it 'creates a new package' do
        expect(package).to be_valid
        expect(package.name).to eq(params[:package_name])
        expect(package.version).to eq(params[:package_version])
        expect(package.package_type).to eq('conan')
        expect(package.conan_metadatum.package_username).to eq(params[:package_username])
        expect(package.conan_metadatum.package_channel).to eq(params[:package_channel])
      end
    end

    shared_examples 'returning an error service response and not creating conan package' do |message:, reason:|
      it_behaves_like 'returning an error service response', message: message
      it { is_expected.to have_attributes(reason: reason) }

      it 'does not create a conan package' do
        expect { service_response }
        .to not_change { Packages::Package.conan.count }
        .and not_change { Packages::PackageFile.count }
      end
    end

    context 'valid params' do
      it_behaves_like 'returning a success service response'

      it 'creates a new package' do
        expect(package).to be_valid
        expect(package.name).to eq(params[:package_name])
        expect(package.version).to eq(params[:package_version])
        expect(package.package_type).to eq('conan')
        expect(package.conan_metadatum.package_username).to eq(params[:package_username])
        expect(package.conan_metadatum.package_channel).to eq(params[:package_channel])
      end

      it_behaves_like 'assigns the package creator'

      it_behaves_like 'assigns build to package' do
        subject { super().payload.fetch(:package) }
      end

      it_behaves_like 'assigns status to package' do
        subject { super().payload.fetch(:package) }
      end
    end

    context 'invalid params' do
      let(:params) { super().merge!(package_username: 'foo/bar') }

      it_behaves_like 'returning an error service response and not creating conan package',
        message: 'Validation failed: Conan metadatum package username is invalid',
        reason: :record_invalid
    end

    context 'with existing recipe' do
      let_it_be(:existing_package) { create(:conan_package, project: project) }

      let(:params) do
        {
          package_name: existing_package.name,
          package_version: existing_package.version,
          package_username: existing_package.conan_metadatum.package_username,
          package_channel: existing_package.conan_metadatum.package_channel
        }
      end

      it_behaves_like 'returning an error service response and not creating conan package',
        message: 'Validation failed: Package recipe already exists',
        reason: :record_invalid
    end

    context 'with package protection rule for different roles and package_name_patterns' do
      using RSpec::Parameterized::TableSyntax

      let_it_be_with_reload(:package_protection_rule) do
        create(:package_protection_rule, package_type: :conan, project: project)
      end

      let_it_be(:project_developer) { create(:user, developer_of: project) }
      let_it_be(:project_maintainer) { create(:user, maintainer_of: project) }
      let_it_be(:project_owner) { project.owner }

      let(:package_name) { params[:package_name] }
      let(:package_name_pattern_no_match) { "#{package_name}_no_match" }

      shared_examples 'an error service response for protected package' do
        it_behaves_like 'returning an error service response and not creating conan package',
          message: 'Package protected.',
          reason: :package_protected
      end

      shared_examples 'an error service response for unauthorized' do
        it_behaves_like 'returning an error service response', message: 'Unauthorized'
        it { is_expected.to have_attributes(reason: :invalid_parameter) }
      end

      before do
        package_protection_rule.update!(
          package_name_pattern: package_name_pattern,
          minimum_access_level_for_push: minimum_access_level_for_push
        )
      end

      # rubocop:disable Layout/LineLength -- Avoid formatting to keep one-line table syntax
      where(:package_name_pattern, :minimum_access_level_for_push, :user, :shared_examples_name) do
        ref(:package_name)                  | :maintainer | ref(:project_developer)  | 'an error service response for protected package'
        ref(:package_name)                  | :maintainer | ref(:project_maintainer) | 'a service response for valid package'
        ref(:package_name)                  | :maintainer | ref(:project_owner)      | 'a service response for valid package'
        ref(:package_name)                  | :owner      | ref(:project_maintainer) | 'an error service response for protected package'
        ref(:package_name)                  | :owner      | ref(:project_owner)      | 'a service response for valid package'
        ref(:package_name)                  | :admin      | ref(:project_owner)      | 'an error service response for protected package'

        ref(:package_name_pattern_no_match) | :maintainer | ref(:project_owner)      | 'a service response for valid package'
        ref(:package_name_pattern_no_match) | :admin      | ref(:project_owner)      | 'a service response for valid package'

        ref(:package_name)                  | :maintainer | nil                      | 'an error service response for unauthorized'
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it_behaves_like params[:shared_examples_name]
      end

      context 'with deploy token' do
        let_it_be(:deploy_token) { create(:deploy_token, :all_scopes, projects: [project]) }
        let_it_be(:user) { nil }

        # rubocop:disable Layout/LineLength -- Avoid formatting to keep one-line table syntax
        where(:package_name_pattern, :minimum_access_level_for_push, :user, :shared_examples_name) do
          ref(:package_name)                  | :maintainer | ref(:deploy_token) | 'an error service response for protected package'
          ref(:package_name)                  | :owner      | ref(:deploy_token) | 'an error service response for protected package'
          ref(:package_name)                  | :admin      | ref(:deploy_token) | 'an error service response for protected package'

          ref(:package_name_pattern_no_match) | :maintainer | ref(:deploy_token) | 'a service response for valid package'
        end
        # rubocop:enable Layout/LineLength

        with_them do
          it_behaves_like params[:shared_examples_name]
        end
      end

      context 'when feature flag :packages_protected_packages_conan is disabled' do
        before do
          stub_feature_flags(packages_protected_packages_conan: false)
        end

        where(:package_name_pattern, :minimum_access_level_for_push, :user) do
          ref(:package_name)                  | :maintainer | ref(:project_developer)
          ref(:package_name)                  | :admin      | ref(:project_owner)
          ref(:package_name_pattern_no_match) | :maintainer | ref(:project_developer)
          ref(:package_name_pattern_no_match) | :admin      | ref(:project_owner)
        end
        with_them do
          it_behaves_like 'a service response for valid package'
        end
      end
    end
  end
end
