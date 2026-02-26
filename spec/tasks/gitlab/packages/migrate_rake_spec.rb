# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/AvoidTestProf -- The tests run inside a database transaction
RSpec.describe 'gitlab:packages namespace rake task', :silence_stdout, feature_category: :package_registry do
  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/packages/migrate'
  end

  describe 'migrate' do
    let_it_be(:local) { ObjectStorage::Store::LOCAL }
    let_it_be(:remote) { ObjectStorage::Store::REMOTE }

    def packages_migrate(target = 'remote')
      run_rake_task('gitlab:packages:migrate', target)
    end

    context 'when object storage is disabled' do
      before do
        stub_package_file_object_storage(enabled: false)
      end

      %w[remote local].each do |target|
        it "doesn't migrate files to #{target} storage" do
          expect { packages_migrate(target) }.to raise_error('Object store is disabled for packages feature')
        end
      end
    end

    context 'when object storage is enabled' do
      let_it_be(:project) { create(:project) }

      before do
        stub_package_file_object_storage
        stub_helm_metadata_cache_object_storage
        stub_npm_metadata_cache_object_storage
        stub_nuget_symbol_object_storage
      end

      context 'when migrating to remote storage' do
        let!(:package_file) { create(:package_file, :pom, file_store: local) }

        it 'migrates local file to object storage' do
          expect { packages_migrate }.to change { package_file.reload.file_store }.from(local).to(remote)
        end

        context 'with Helm metadata cache' do
          let_it_be(:helm_cache) { create(:helm_metadata_cache, project: project, file_store: local) }

          it 'migrates Helm metadata caches stored locally to object storage' do
            expect { packages_migrate }.to change { helm_cache.reload.file_store }.from(local).to(remote)
          end
        end

        context 'with NPM metadata cache' do
          let_it_be(:npm_cache) { create(:npm_metadata_cache, project: project, file_store: local) }

          it 'migrates NPM metadata caches stored locally to object storage' do
            expect { packages_migrate }.to change { npm_cache.reload.file_store }.from(local).to(remote)
          end
        end

        context 'with NuGet symbol' do
          let_it_be(:nuget_symbol) do
            create(:nuget_symbol, file_store: local,
              package: create(:nuget_package, project: project))
          end

          it 'migrates NuGet symbols stored locally to object storage' do
            expect { packages_migrate }.to change { nuget_symbol.reload.file_store }.from(local).to(remote)
          end
        end

        context 'when an error occurs during migration' do
          before do
            allow_next_instance_of(Packages::PackageFileUploader) do |instance|
              allow(instance).to receive(:migrate!).and_raise(StandardError.new('Migration failed'))
            end
          end

          it 'logs the error and continues' do
            expect { packages_migrate }.to output(
              /Failed to transfer package file #{package_file.id} with error: Migration failed/
            ).to_stdout

            expect { packages_migrate('remote') }.not_to raise_error
          end
        end
      end

      context 'when migrating to local storage' do
        let!(:package_file) { create(:package_file, :pom, :object_storage) }

        it 'migrates remote file to local storage' do
          expect { packages_migrate('local') }.to change { package_file.reload.file_store }.from(remote).to(local)
        end

        context 'with Helm metadata cache' do
          let!(:helm_cache) { create(:helm_metadata_cache, :object_storage, project: project) }

          it 'migrates Helm metadata caches from object storage to local' do
            expect { packages_migrate('local') }.to change { helm_cache.reload.file_store }
              .from(remote).to(local)
          end
        end

        context 'with NPM metadata cache' do
          let!(:npm_cache) { create(:npm_metadata_cache, :object_storage, project: project) }

          it 'migrates NPM metadata caches from object storage to local' do
            expect { packages_migrate('local') }.to change { npm_cache.reload.file_store }
              .from(remote).to(local)
          end
        end

        context 'with NuGet symbol' do
          let!(:nuget_symbol) do
            create(:nuget_symbol, :object_storage, package: create(:nuget_package, project: project))
          end

          it 'migrates NuGet symbols from object storage to local' do
            expect { packages_migrate('local') }.to change { nuget_symbol.reload.file_store }
              .from(remote).to(local)
          end
        end

        context 'when an error occurs during migration' do
          before do
            allow_next_instance_of(Packages::PackageFileUploader) do |instance|
              allow(instance).to receive(:migrate!).and_raise(StandardError.new('Migration failed'))
            end
          end

          it 'logs the error and continues' do
            expect { packages_migrate('local') }.to output(
              /Failed to transfer package file #{package_file.id} with error: Migration failed/
            ).to_stdout

            expect { packages_migrate('local') }.not_to raise_error
          end
        end
      end
    end

    context 'with invalid target' do
      it 'shows error message and exits' do
        expect do
          packages_migrate('invalid')
        end.to output(/Error: Target must be 'remote' or 'local'/).to_stdout.and raise_error(SystemExit)
      end
    end

    context 'with no target specified' do
      before do
        stub_package_file_object_storage
      end

      it 'defaults to remote migration' do
        expect { packages_migrate }.to output(/Starting transfer of package files to remote storage/).to_stdout
      end
    end
  end
end
# rubocop:enable RSpec/AvoidTestProf
