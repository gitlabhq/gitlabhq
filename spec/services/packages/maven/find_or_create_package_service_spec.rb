# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Maven::FindOrCreatePackageService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:app_name) { 'my-app' }
  let(:path) { "sandbox/test/app/#{app_name}" }
  let(:version) { '1.0.0' }
  let(:file_name) { 'test.jar' }
  let(:param_path) { "#{path}/#{version}" }
  let(:params) { { path: param_path, file_name: file_name } }
  let(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    subject { service.execute }

    shared_examples 'reuse existing package' do
      it { expect { subject }.not_to change { Packages::Package.count } }

      it 'returns the existing package' do
        expect(subject.payload).to eq(package: existing_package)
      end
    end

    shared_examples 'create package' do
      it { expect { subject }.to change { Packages::Package.count }.by(1) }

      it 'sets the proper name and version', :aggregate_failures do
        pkg = subject.payload[:package]

        expect(pkg.name).to eq(path)
        expect(pkg.version).to eq(version)
      end

      context 'with optional attributes' do
        subject { service.execute.payload[:package] }

        it_behaves_like 'assigns build to package'
        it_behaves_like 'assigns status to package'
      end
    end

    context 'path with version' do
      # Note that "path with version" and "file type maven metadata xml" only exists for snapshot versions
      # In other words, we will never have an metadata xml upload on a path with version for a non snapshot version
      where(:package_exist, :file_type, :snapshot_version, :shared_example_name) do
        true  | :jar       | false | 'reuse existing package'
        false | :jar       | false | 'create package'
        true  | :jar       | true  | 'reuse existing package'
        false | :jar       | true  | 'create package'
        true  | :maven_xml | true  | 'reuse existing package'
        false | :maven_xml | true  | 'create package'
      end

      with_them do
        let(:version) { snapshot_version ? '1.0-SNAPSHOT' : '1.0.0' }
        let(:file_name) { file_type == :maven_xml ? 'maven-metadata.xml' : 'test.jar' }

        let!(:existing_package) do
          if package_exist
            create(:maven_package, name: path, version: version, project: project)
          end
        end

        it_behaves_like params[:shared_example_name]
      end
    end

    context 'path without version' do
      let(:param_path) { path }
      let(:version) { nil }

      context 'maven-metadata.xml file' do
        let(:file_name) { 'maven-metadata.xml' }

        context 'with existing package' do
          let!(:existing_package) { create(:maven_package, name: path, version: version, project: project) }

          it_behaves_like 'reuse existing package'
        end

        context 'without existing package' do
          it_behaves_like 'create package'
        end
      end
    end

    context 'with a build' do
      let_it_be(:pipeline) { create(:ci_pipeline, user: user) }

      let(:build) { double('build', pipeline: pipeline) }
      let(:params) { { path: param_path, file_name: file_name, build: build } }

      it 'creates a build_info' do
        expect { subject }.to change { Packages::BuildInfo.count }.by(1)
      end
    end

    context 'when package duplicates are not allowed' do
      let_it_be_with_refind(:package_settings) { create(:namespace_package_setting, :group, maven_duplicates_allowed: false) }
      let_it_be_with_refind(:group) { package_settings.namespace }
      let_it_be_with_refind(:project) { create(:project, group: group) }

      let!(:existing_package) { create(:maven_package, name: path, version: version, project: project) }

      it { expect { subject }.not_to change { project.package_files.count } }

      it 'returns an error', :aggregate_failures do
        expect(subject.payload).to be_empty
        expect(subject.errors).to include('Duplicate package is not allowed')
      end

      context 'when uploading to the versionless package which contains metadata about all versions' do
        let(:version) { nil }
        let(:param_path) { path }

        it_behaves_like 'reuse existing package'
      end

      context 'when uploading different non-duplicate files to the same package' do
        before do
          package_file = existing_package.package_files.find_by(file_name: 'my-app-1.0-20180724.124855-1.jar')
          package_file.destroy!
        end

        it_behaves_like 'reuse existing package'
      end

      context 'when the package name matches the exception regex' do
        before do
          package_settings.update!(maven_duplicate_exception_regex: existing_package.name)
        end

        it_behaves_like 'reuse existing package'
      end

      context 'when the package version matches the exception regex' do
        before do
          package_settings.update!(maven_duplicate_exception_regex: existing_package.version)
        end

        it_behaves_like 'reuse existing package'
      end
    end
  end
end
