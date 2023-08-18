# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Go::CreatePackageService, feature_category: :package_registry do
  let_it_be(:project) { create :project_empty_repo, path: 'my-go-lib' }
  let_it_be(:mod) { create :go_module, project: project }

  before_all do
    create :go_module_commit, :module, project: project, tag: 'v1.0.0'
  end

  shared_examples 'creates a package' do |files:|
    it "returns a valid package with #{files ? files.to_s : 'no'} file(s)" do
      expect(subject).to be_valid
      expect(subject.name).to eq(version.mod.name)
      expect(subject.version).to eq(version.name)
      expect(subject.package_type).to eq('golang')
      expect(subject.created_at).to eq(version.commit.committed_date)
      expect(subject.package_files.count).to eq(files)
    end
  end

  shared_examples 'creates a package file' do |type|
    it "returns a package with a #{type} file" do
      file_name = "#{version.name}.#{type}"
      expect(subject.package_files.map { |f| f.file_name }).to include(file_name)

      file = subject.package_files.with_file_name(file_name).first
      expect(file).not_to be_nil
      expect(file.file).not_to be_nil
      expect(file.size).to eq(file.file.size)
      expect(file.file_name).to eq(file_name)
      expect(file.file_md5).not_to be_nil
      expect(file.file_sha1).not_to be_nil
      expect(file.file_sha256).not_to be_nil
    end

    context 'with FIPS mode', :fips_mode do
      it 'does not generate file_md5' do
        file_name = "#{version.name}.#{type}"
        expect(subject.package_files.map { |f| f.file_name }).to include(file_name)

        file = subject.package_files.with_file_name(file_name).first
        expect(file).not_to be_nil
        expect(file.file).not_to be_nil
        expect(file.size).to eq(file.file.size)
        expect(file.file_name).to eq(file_name)
        expect(file.file_md5).to be_nil
        expect(file.file_sha1).not_to be_nil
        expect(file.file_sha256).not_to be_nil
      end
    end
  end

  describe '#execute' do
    subject { described_class.new(project, nil, version: version).execute }

    let(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.0' }

    context 'with no existing package' do
      it_behaves_like 'creates a package', files: 2
      it_behaves_like 'creates a package file', :mod
      it_behaves_like 'creates a package file', :zip

      it 'creates a new package' do
        expect { subject }
          .to change { project.packages.count }.by(1)
          .and change { Packages::PackageFile.count }.by(2)
      end
    end

    context 'with an existing package' do
      before do
        described_class.new(project, version: version).execute
      end

      it_behaves_like 'creates a package', files: 2
      it_behaves_like 'creates a package file', :mod
      it_behaves_like 'creates a package file', :zip

      it 'does not create a package or files' do
        expect { subject }
          .to not_change { project.packages.count }
          .and not_change { Packages::PackageFile.count }
      end
    end
  end
end
