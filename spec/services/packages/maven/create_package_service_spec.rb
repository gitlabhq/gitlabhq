# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Maven::CreatePackageService, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }

  let(:app_name) { 'my-app' }
  let(:version) { '1.0-SNAPSHOT' }
  let(:path) { "my/company/app/#{app_name}" }
  let(:path_with_version) { "#{path}/#{version}" }

  describe '#execute' do
    let(:package) { subject[:package] }

    subject { described_class.new(project, user, params).execute }

    shared_examples 'valid package' do
      it_behaves_like 'returning a success service response'

      it 'creates a new package with metadatum' do
        expect(package).to be_valid
        expect(package.name).to eq(path)
        expect(package.version).to eq(version)
        expect(package.package_type).to eq('maven')
        expect(package.maven_metadatum).to be_valid
        expect(package.maven_metadatum.path).to eq(path_with_version)
        expect(package.maven_metadatum.app_group).to eq('my.company.app')
        expect(package.maven_metadatum.app_name).to eq(app_name)
        expect(package.maven_metadatum.app_version).to eq(version)
      end

      it_behaves_like 'assigns the package creator'
    end

    context 'with version' do
      let(:params) do
        {
          path: path_with_version,
          name: path,
          version: version
        }
      end

      it_behaves_like 'valid package'
    end

    context 'without version' do
      let(:version) { nil }
      let(:path_with_version) { path }

      let(:params) do
        {
          path: path,
          name: path,
          version: nil
        }
      end

      it_behaves_like 'valid package'
    end

    context 'without path' do
      let(:params) do
        {
          name: path,
          version: version
        }
      end

      it_behaves_like 'returning an error service response',
        message: "Validation failed: Maven metadatum path can't be blank" do
        it { is_expected.to have_attributes(reason: :invalid_parameter) }
      end
    end

    context 'with an exisiting package' do
      let!(:package) { create(:maven_package, project: project, name: path, version: version) }

      let(:params) do
        {
          path: path_with_version,
          name: path,
          version: version
        }
      end

      it_behaves_like 'returning an error service response',
        message: 'Validation failed: Name has already been taken' do
        it { is_expected.to have_attributes(reason: :name_taken) }
      end
    end

    context 'with package protection rule for different roles and package_name_patterns', :enable_admin_mode do
      using RSpec::Parameterized::TableSyntax

      let_it_be_with_reload(:package_protection_rule) do
        create(:package_protection_rule, package_type: :maven, project: project)
      end

      let_it_be(:project_developer) { create(:user, developer_of: project) }
      let_it_be(:project_maintainer) { create(:user, maintainer_of: project) }
      let_it_be(:project_owner) { project.owner }
      let_it_be(:instance_admin) { create(:admin) }

      let(:params) do
        {
          path: path_with_version,
          name: path,
          version: version
        }
      end

      let(:package_name) { path }

      let(:package_name_pattern_no_match) { "#{package_name}_no_match" }

      before do
        package_protection_rule.update!(package_name_pattern: package_name_pattern,
          minimum_access_level_for_push: minimum_access_level_for_push)
      end

      shared_examples 'protected package' do
        it_behaves_like 'returning an error service response', message: "Package protected."
        it { is_expected.to have_attributes(reason: :package_protected) }

        it 'does not create any maven-related package records' do
          expect { subject }
            .to not_change { Packages::Package.count }
            .and not_change { Packages::Package.maven.count }
            .and not_change { Packages::PackageFile.count }
        end
      end

      shared_examples 'an error service response for unauthorized' do
        it { expect { subject }.to raise_error ArgumentError, 'Unauthorized' }
      end

      where(:package_name_pattern, :minimum_access_level_for_push, :user, :shared_examples_name) do
        ref(:package_name)                  | :maintainer | ref(:project_developer)         | 'protected package'
        ref(:package_name)                  | :maintainer | ref(:project_maintainer)        | 'valid package'
        ref(:package_name)                  | :maintainer | ref(:project_owner)             | 'valid package'
        ref(:package_name)                  | :maintainer | ref(:instance_admin)            | 'valid package'

        ref(:package_name)                  | :owner      | ref(:project_maintainer)        | 'protected package'
        ref(:package_name)                  | :owner      | ref(:project_owner)             | 'valid package'
        ref(:package_name)                  | :owner      | ref(:instance_admin)            | 'valid package'

        ref(:package_name)                  | :admin      | ref(:project_owner)             | 'protected package'
        ref(:package_name)                  | :admin      | ref(:instance_admin)            | 'valid package'

        ref(:package_name_pattern_no_match) | :maintainer | ref(:project_owner)             | 'valid package'
        ref(:package_name_pattern_no_match) | :admin      | ref(:project_owner)             | 'valid package'
      end

      with_them do
        it_behaves_like params[:shared_examples_name]
      end

      context 'with deploy token' do
        let_it_be(:deploy_token) { create(:deploy_token, :all_scopes, projects: [project]) }

        # This is necessary because of the shared example 'assigns the package creator'
        # that requires the variable `user` to be nil
        # because packages created by a deploy token do not have an assigned user.
        let(:user) { nil }

        subject { described_class.new(project, deploy_token, params).execute }

        where(:package_name_pattern, :minimum_access_level_for_push, :shared_examples_name) do
          ref(:package_name)                  | :maintainer | 'protected package'
          ref(:package_name)                  | :owner      | 'protected package'
          ref(:package_name)                  | :admin      | 'protected package'

          ref(:package_name_pattern_no_match) | :admin      | 'valid package'
        end

        with_them do
          it_behaves_like params[:shared_examples_name]
        end
      end
    end
  end
end
