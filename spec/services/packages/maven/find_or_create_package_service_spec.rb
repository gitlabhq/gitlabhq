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

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.new(project, user, params).execute }

    RSpec.shared_examples 'reuse existing package' do
      it { expect { subject}.not_to change { Packages::Package.count } }

      it { is_expected.to eq(existing_package) }
    end

    RSpec.shared_examples 'create package' do
      it { expect { subject }.to change { Packages::Package.count }.by(1) }

      it 'sets the proper name and version' do
        pkg = subject

        expect(pkg.name).to eq(path)
        expect(pkg.version).to eq(version)
      end

      it_behaves_like 'assigns build to package'
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
  end
end
