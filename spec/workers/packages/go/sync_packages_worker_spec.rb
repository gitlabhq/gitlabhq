# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Go::SyncPackagesWorker, type: :worker, feature_category: :package_registry do
  include_context 'basic Go module'

  before do
    project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
  end

  def perform(ref_name, path)
    described_class.new.perform(project.id, ref_name, path)
  end

  def validate_package(package, mod, ver)
    expect(package).not_to be_nil
    expect(package.name).to eq(mod.name)
    expect(package.version).to eq(ver.name)
    expect(package.package_type).to eq('golang')
    expect(package.created_at).to eq(ver.commit.committed_date)
    expect(package.package_files.count).to eq(2)
  end

  shared_examples 'it creates a package' do |path, version, exists: false|
    subject { perform(version, path) }

    it "returns a package for example.com/project#{path.empty? ? '' : '/' + path}@#{version}" do
      expect { subject }
        .to change { project.packages.count }.by(exists ? 0 : 1)
        .and change { Packages::PackageFile.count }.by(exists ? 0 : 2)

      mod = create :go_module, project: project, path: path
      ver = create :go_module_version, :tagged, mod: mod, name: version
      validate_package(subject, mod, ver)
    end
  end

  describe '#perform' do
    context 'with no existing packages' do
      it_behaves_like 'it creates a package', '', 'v1.0.1'
      it_behaves_like 'it creates a package', '', 'v1.0.2'
      it_behaves_like 'it creates a package', '', 'v1.0.3'
      it_behaves_like 'it creates a package', 'mod', 'v1.0.3'
      it_behaves_like 'it creates a package', 'v2', 'v2.0.0'
    end

    context 'with existing packages' do
      before do
        mod = create :go_module, project: project
        ver = create :go_module_version, :tagged, mod: mod, name: 'v1.0.1'
        Packages::Go::CreatePackageService.new(project, nil, version: ver).execute
      end

      it_behaves_like 'it creates a package', '', 'v1.0.1', exists: true
      it_behaves_like 'it creates a package', '', 'v1.0.2'
      it_behaves_like 'it creates a package', '', 'v1.0.3'
      it_behaves_like 'it creates a package', 'mod', 'v1.0.3'
      it_behaves_like 'it creates a package', 'v2', 'v2.0.0'

      context 'marked as pending_destruction' do
        before do
          project.packages.each(&:pending_destruction!)
        end

        it_behaves_like 'it creates a package', '', 'v1.0.1'
        it_behaves_like 'it creates a package', '', 'v1.0.2'
        it_behaves_like 'it creates a package', '', 'v1.0.3'
        it_behaves_like 'it creates a package', 'mod', 'v1.0.3'
        it_behaves_like 'it creates a package', 'v2', 'v2.0.0'
      end
    end

    context 'with a package that exceeds project limits' do
      before do
        Plan.default.actual_limits.update!({ golang_max_file_size: 1 })
      end

      it 'logs an exception' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(instance_of(::Packages::Go::CreatePackageService::GoZipSizeError))

        perform('v2.0.0', 'v2')
      end
    end

    where(:path, :version) do
      [
        ['', 'v1.0.1'],
        ['', 'v1.0.2'],
        ['', 'v1.0.3'],
        ['mod', 'v1.0.3'],
        ['v2', 'v2.0.0']
      ]
    end

    with_them do
      it_behaves_like 'an idempotent worker' do
        let(:job_args) { [project.id, version, path] }

        it 'creates a package' do
          expect { subject }
            .to change { project.packages.count }.by(1)
            .and change { Packages::PackageFile.count }.by(2)

          mod = create :go_module, project: project, path: path
          ver = create :go_module_version, :tagged, mod: mod, name: version
          package = ::Packages::Go::PackageFinder.new(project, mod.name, ver.name).execute
          validate_package(package, mod, ver)
        end
      end
    end
  end
end
