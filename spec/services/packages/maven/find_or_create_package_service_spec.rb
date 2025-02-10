# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Maven::FindOrCreatePackageService, feature_category: :package_registry do
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

    subject(:execute_service) { service.execute }

    shared_examples 'reuse existing package' do
      it { expect { subject }.not_to change { Packages::Package.count } }

      it 'returns the existing package' do
        expect(subject.payload).to eq(package: existing_package)
      end
    end

    shared_examples 'create package' do
      it { expect { subject }.to change { Packages::Package.count }.by(1) }

      it_behaves_like 'returning a success service response'

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

    shared_examples 'returning an error' do |with_message: ''|
      it { expect { subject }.not_to change { project.package_files.count } }

      it_behaves_like 'returning an error service response', message: with_message do
        it { expect(subject.payload).to be_empty }
      end
    end

    context 'with path including version' do
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

    context 'with path not including version' do
      let(:param_path) { path }
      let(:version) { nil }

      context 'and maven-metadata.xml file' do
        let(:file_name) { 'maven-metadata.xml' }

        context 'with existing package' do
          let!(:existing_package) { create(:maven_package, name: path, version: version, project: project) }

          it_behaves_like 'reuse existing package'

          context 'and marked as pending_destruction' do
            before do
              existing_package.pending_destruction!
            end

            it_behaves_like 'create package'
          end
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
        expect { execute_service }.to change { Packages::BuildInfo.count }.by(1)
      end

      context 'with multiple files for the same package and the same pipeline' do
        let(:file_2_params) { params.merge(file_name: 'test2.jar') }
        let(:file_3_params) { params.merge(file_name: 'test3.jar') }

        it 'creates a single build info' do
          expect do
            described_class.new(project, user, params).execute
            described_class.new(project, user, file_2_params).execute
            described_class.new(project, user, file_3_params).execute
          end.to change { ::Packages::BuildInfo.count }.by(1)
        end
      end
    end

    context 'when package duplicates are not allowed' do
      let_it_be_with_refind(:package_settings) do
        create(:namespace_package_setting, :group, maven_duplicates_allowed: false)
      end

      let_it_be_with_refind(:group) { package_settings.namespace }
      let_it_be_with_refind(:project) { create(:project, group: group) }

      let!(:existing_package) { create(:maven_package, name: path, version: version, project: project) }

      let(:existing_file_name) { file_name }
      let(:jar_file) { existing_package.package_files.with_file_name_like('%.jar').first }

      before do
        jar_file.update_column(:file_name, existing_file_name)
      end

      it_behaves_like 'returning an error', with_message: 'Duplicate package is not allowed'

      context 'for a SNAPSHOT version' do
        let(:version) { '1.0.0-SNAPSHOT' }

        it_behaves_like 'returning an error', with_message: 'Duplicate package is not allowed'
      end

      context 'when uploading to the versionless package which contains metadata about all versions' do
        let(:version) { nil }
        let(:param_path) { path }

        it_behaves_like 'reuse existing package'
      end

      context 'when uploading different non-duplicate files to the same package' do
        before do
          jar_file.destroy!
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

      context 'when uploading a similar package file name with a classifier' do
        let(:existing_file_name) { 'test.jar' }
        let(:file_name) { 'test-javadoc.jar' }

        it_behaves_like 'reuse existing package'

        context 'for a SNAPSHOT version' do
          let(:version) { '1.0.0-SNAPSHOT' }
          let(:existing_file_name) { 'test-1.0-20230303.163304-1.jar' }
          let(:file_name) { 'test-1.0-20230303.163304-1-javadoc.jar' }

          it_behaves_like 'reuse existing package'
        end
      end
    end

    context 'when package duplicates are allowed' do
      let_it_be_with_refind(:package_settings) do
        create(:namespace_package_setting, :group, maven_duplicates_allowed: true)
      end

      let_it_be_with_refind(:group) { package_settings.namespace }
      let_it_be_with_refind(:project) { create(:project, group: group) }

      let!(:existing_package) { create(:maven_package, name: path, version: version, project: project) }

      let(:existing_file_name) { file_name }
      let(:jar_file) { existing_package.package_files.with_file_name_like('%.jar').first }

      before do
        jar_file.update_column(:file_name, existing_file_name)
      end

      it_behaves_like 'reuse existing package'

      context 'when the package name matches the exception regex' do
        before do
          package_settings.update!(maven_duplicate_exception_regex: existing_package.name)
        end

        it_behaves_like 'returning an error', with_message: 'Duplicate package is not allowed'
      end

      context 'when the package version matches the exception regex' do
        before do
          package_settings.update!(maven_duplicate_exception_regex: existing_package.version)
        end

        it_behaves_like 'returning an error', with_message: 'Duplicate package is not allowed'
      end

      context 'when the exception regex is blank' do
        before do
          package_settings.update!(maven_duplicate_exception_regex: '')
        end

        it_behaves_like 'reuse existing package'
      end

      context 'when both the package name and version does not match the exception regex' do
        before do
          package_settings.update!(maven_duplicate_exception_regex: 'asdf42')
        end

        it_behaves_like 'reuse existing package'
      end
    end

    context 'with a very large file name' do
      let(:params) { super().merge(file_name: 'a' * (described_class::MAX_FILE_NAME_LENGTH + 1)) }

      it_behaves_like 'returning an error', with_message: 'File name is too long'
    end

    context 'with invalid params causing the erroneous service response' do
      let(:params) { super().merge(path: '/') }

      it_behaves_like 'returning an error',
        with_message: "Validation failed: Maven metadatum app group can't be blank, " \
                      "Maven metadatum app group is invalid, Maven metadatum app name can't be blank, " \
                      "Maven metadatum app name is invalid, Name can't be blank, Name is invalid"
    end

    context 'with parallel execution' do
      it 'only creates one package' do
        expect do
          with_threads { described_class.new(project, user, params).execute }
        end.to change { Packages::Maven::Package.count }.by(1)
      end

      context 'when CreatePackageService responds with a name_taken error' do
        before do
          retries = 0
          allow_next_instance_of(::Packages::Maven::CreatePackageService) do |service|
            allow(service).to receive(:execute) do
              if (retries += 1) == 1
                ServiceResponse.error(message: 'Name has already been taken', reason: :name_taken)
              else
                ServiceResponse.success(payload: { package: create(:maven_package) })
              end
            end
          end
          allow(::Packages::Maven::PackageFinder).to receive(:new).and_call_original
        end

        it 'retries and calls the finder twice' do
          execute_service

          expect(::Packages::Maven::PackageFinder).to have_received(:new).twice
        end
      end
    end
  end

  def with_threads(count: 5, &block)
    return unless block

    # create a race condition - structure from https://blog.arkency.com/2015/09/testing-race-conditions/
    wait_for_it = true

    threads = Array.new(count) do
      Thread.new do
        # A loop to make threads busy until we `join` them
        true while wait_for_it

        yield
      end
    end

    wait_for_it = false
    threads.each(&:join)
  end
end
