# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Npm::CreatePackageService do
  let(:namespace) {create(:namespace)}
  let(:project) { create(:project, namespace: namespace) }
  let(:user) { create(:user) }
  let(:version) { '1.0.1' }

  let(:params) do
    Gitlab::Json.parse(fixture_file('packages/npm/payload.json')
        .gsub('@root/npm-test', package_name)
        .gsub('1.0.1', version)).with_indifferent_access
      .merge!(override)
  end

  let(:override) { {} }
  let(:package_name) { "@#{namespace.path}/my-app" }

  subject { described_class.new(project, user, params).execute }

  shared_examples 'valid package' do
    it 'creates a package' do
      expect { subject }
        .to change { Packages::Package.count }.by(1)
        .and change { Packages::Package.npm.count }.by(1)
        .and change { Packages::Tag.count }.by(1)
    end

    it_behaves_like 'assigns the package creator' do
      let(:package) { subject }
    end

    it { is_expected.to be_valid }

    it 'creates a package with name and version' do
      package = subject

      expect(package.name).to eq(package_name)
      expect(package.version).to eq(version)
    end

    it { expect(subject.name).to eq(package_name) }
    it { expect(subject.version).to eq(version) }

    context 'with build info' do
      let(:job) { create(:ci_build, user: user) }
      let(:params) { super().merge(build: job) }

      it_behaves_like 'assigns build to package'
      it_behaves_like 'assigns status to package'

      it 'creates a package file build info' do
        expect { subject }.to change { Packages::PackageFileBuildInfo.count }.by(1)
      end
    end
  end

  describe '#execute' do
    context 'scoped package' do
      it_behaves_like 'valid package'
    end

    context 'scoped package not following the naming convention' do
      let(:package_name) { '@any-scope/package' }

      it_behaves_like 'valid package'
    end

    context 'unscoped package' do
      let(:package_name) { 'unscoped-package' }

      it_behaves_like 'valid package'
    end

    context 'package already exists' do
      let(:package_name) { "@#{namespace.path}/my_package" }
      let!(:existing_package) { create(:npm_package, project: project, name: package_name, version: '1.0.1') }

      it { expect(subject[:http_status]).to eq 403 }
      it { expect(subject[:message]).to be 'Package already exists.' }
    end

    context 'file size above maximum limit' do
      before do
        params['_attachments']["#{package_name}-#{version}.tgz"]['length'] = project.actual_limits.npm_max_file_size + 1
      end

      it { expect(subject[:http_status]).to eq 400 }
      it { expect(subject[:message]).to be 'File is too large.' }
    end

    [
      '@inv@lid_scope/package',
      '@scope/sub/group',
      '@scope/../../package',
      '@scope%2e%2e%2fpackage'
    ].each do |invalid_package_name|
      context "with invalid name #{invalid_package_name}" do
        let(:package_name) { invalid_package_name }

        it 'raises a RecordInvalid error' do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'with empty versions' do
      let(:override) { { versions: {} } }

      it { expect(subject[:http_status]).to eq 400 }
      it { expect(subject[:message]).to eq 'Version is empty.' }
    end

    context 'with invalid versions' do
      using RSpec::Parameterized::TableSyntax

      where(:version) do
        [
          '1',
          '1.2',
          '1./2.3',
          '../../../../../1.2.3',
          '%2e%2e%2f1.2.3'
        ]
      end

      with_them do
        it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Version is invalid') }
      end
    end
  end
end
