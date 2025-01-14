# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::DeprecatePackageService, feature_category: :package_registry do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project) { create(:project, namespace: namespace) }

  let_it_be(:package_name) { "@#{namespace.path}/my-app" }
  let_it_be_with_reload(:package_1) do
    create(:npm_package, project: project, name: package_name, version: '1.0.1').tap do |package|
      create(:npm_metadatum, package: package)
    end
  end

  let_it_be(:package_2) do
    create(:npm_package, project: project, name: package_name, version: '1.0.2').tap do |package|
      create(:npm_metadatum, package: package)
    end
  end

  let_it_be(:package_3) { create(:npm_package, project: project, name: package_name, version: '1.0.3') }

  let(:service) { described_class.new(project, params) }

  subject(:execute) { service.execute }

  describe '#execute' do
    shared_examples 'enqueues metadata cache worker' do
      it 'enqueues metadata cache worker' do
        expect(::Packages::Npm::CreateMetadataCacheWorker).to receive(:perform_async)
          .with(project.id, params['package_name'])

        execute
      end
    end

    context 'when passing deprecatation message' do
      let(:params) { build_params(['1.0.1', '1.0.2']) }

      before do
        package_json = package_2.npm_metadatum.package_json
        package_2.npm_metadatum.update_column(:package_json,
          package_json.merge('deprecated' => 'old deprecation message'))
      end

      it 'adds or updates the deprecated field and sets status to `deprecated`' do
        expect { execute }
          .to change {
                package_1.reload.npm_metadatum.package_json['deprecated']
              }.to('This version is deprecated')
          .and change {
                 package_2.reload.npm_metadatum.package_json['deprecated']
               }.from('old deprecation message').to('This version is deprecated')
          .and change { package_1.status }.from('default').to('deprecated')
          .and change { package_2.status }.from('default').to('deprecated')
        expect(execute).to be_success
      end

      it 'executes 8 queries' do
        queries = ActiveRecord::QueryRecorder.new do
          execute
        end

        # 1. each_batch lower bound
        # 2. each_batch upper bound
        # 3. SELECT packages_packages.id, packages_packages.version FROM packages_packages
        # 4. SELECT packages_npm_metadata.* FROM packages_npm_metadata
        # 5. TRANSACTION
        # 6. INSERT INSERT INTO packages_npm_metadata (...) VALUES (...) DO UPDATE SET ...
        # 7. UPDATE packages_packages SET status =
        # 8. TRANSACTION
        expect(queries.count).to eq(8)
      end

      it_behaves_like 'enqueues metadata cache worker'

      context 'when the database error has happened' do
        let(:exception) { ActiveRecord::ConnectionTimeoutError }

        it 'rolls back previously successfully executed operations' do
          allow(::Packages::Package).to receive(:id_in).and_raise(exception)

          expect { execute }.to raise_error(exception)
            .and not_change {
              package_1.reload.npm_metadatum.package_json['deprecated']
            }.from(nil)
            .and not_change {
              package_2.reload.npm_metadatum.package_json['deprecated']
            }.from('old deprecation message')
        end
      end
    end

    context 'when passing deprecated as empty string' do
      let(:params) { build_params([package_1.version], '') }

      before do
        package_json = package_1.npm_metadatum.package_json
        package_1.npm_metadatum.update!(package_json: package_json.merge('deprecated' => 'This version is deprecated'))
        package_1.update!(status: :deprecated)
      end

      it 'removes the deprecation warning and sets status to `default`', :aggregate_failures do
        expect { execute }
          .to change {
                package_1.reload.npm_metadatum.package_json['deprecated']
              }.from('This version is deprecated').to(nil)
          .and change { package_1.status }.from('deprecated').to('default')
        expect(execute).to be_success
      end

      it_behaves_like 'enqueues metadata cache worker'
    end

    context 'when a package does not have a metadatum' do
      let(:params) { build_params([package_3.version]) }

      it 'creates a new metadatum', :aggregate_failures do
        expect { execute }.to change { ::Packages::Npm::Metadatum.count }.by(1)
        expect(package_3.npm_metadatum.package_json['deprecated']).to eq('This version is deprecated')
        expect(execute).to be_success
      end

      it 'avoids N+1 database queries', :use_sql_query_cache do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { execute }

        create(:npm_package, project: project, name: package_name, version: '1.0.4')
        create(:npm_package, project: project, name: package_name, version: '1.0.5')
        params['versions'].merge!(build_params(['1.0.4', '1.0.5'])['versions'])

        expect { described_class.new(project, params).execute }.not_to exceed_query_limit(control)
      end

      it_behaves_like 'enqueues metadata cache worker'

      context 'when metadata is invalid' do
        before do
          allow_next_instance_of(::Packages::Npm::Metadatum) do |metadatum|
            allow(metadatum).to receive(:valid?).and_return(false)
          end
        end

        it 'tracks the error' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            an_instance_of(ActiveRecord::RecordInvalid),
            class: described_class.name,
            package_id: package_3.id
          )

          execute
        end
      end
    end

    context 'when no metadata to update or create' do
      let(:params) { build_params([package_1.version]) }

      before do
        package_json = package_1.npm_metadatum.package_json
        package_1.npm_metadatum.update_column(:package_json,
          package_json.merge('deprecated' => 'This version is deprecated'))
      end

      it 'does enqueue metadata cache worker' do
        expect(::Packages::Npm::CreateMetadataCacheWorker).not_to receive(:perform_async)

        execute
      end
    end
  end

  def build_params(versions, deprecation_msg = 'This version is deprecated')
    {
      'package_name' => package_name,
      'versions' => versions.index_with do |version|
        {
          'name' => package_name,
          'version' => version,
          'deprecated' => deprecation_msg,
          'dist' => {
            'tarball' => 'http://localhost/tarball.tgz',
            'shasum' => '1234567890'
          }
        }
      end
    }
  end
end
