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

  let_it_be_with_reload(:package_2) do
    create(:npm_package, project: project, name: package_name, version: '1.0.2').tap do |package|
      create(:npm_metadatum, package: package)
    end
  end

  let_it_be(:package_3) { create(:npm_package, project: project, name: package_name, version: '1.0.3') }
  let_it_be(:package_4) { create(:npm_package, project: project, name: package_name, version: '1.0.4') }

  let(:service) { described_class.new(project, params) }

  subject(:execute) { service.execute }

  describe '#execute' do
    shared_examples 'enqueues metadata cache worker' do
      it 'enqueues metadata cache worker' do
        expect(::Packages::Npm::CreateMetadataCacheWorker).to receive(:perform_async)
          .with(project.id, params['name'])

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

    context 'when passing mixed payload with different deprecation messages' do
      let(:params) do
        build_params({
          package_1.version => 'Version 1 is deprecated',
          package_2.version => '',
          package_4.version => 'Version 4 is deprecated'
        })
      end

      before do
        # Set package_1 as already deprecated with a different message
        package_json_1 = package_1.npm_metadatum.package_json
        package_1.npm_metadatum.update!(package_json: package_json_1.merge('deprecated' => 'Old deprecation'))
        package_1.update!(status: :deprecated)

        # Set package_2 as already deprecated (will be un-deprecated)
        package_json_2 = package_2.npm_metadatum.package_json
        package_2.npm_metadatum.update!(package_json: package_json_2.merge('deprecated' => 'Should be removed'))
        package_2.update!(status: :deprecated)

        # package_4 has no metadatum yet
      end

      it 'applies the correct deprecation message and status to each package', :aggregate_failures do
        expect { execute }
          .to change {
                package_1.reload.npm_metadatum.package_json['deprecated']
              }.from('Old deprecation').to('Version 1 is deprecated')
          .and change {
                 package_2.reload.npm_metadatum.package_json['deprecated']
               }.from('Should be removed').to(nil)
          .and not_change { package_1.reload.status }
          .and change { package_2.status }.from('deprecated').to('default')
          .and change { ::Packages::Npm::Metadatum.count }.by(1)
          .and change {
                 package_4.reload.npm_metadatum&.package_json&.dig('deprecated')
               }.from(nil).to('Version 4 is deprecated')
          .and change { package_4.reload.status }.from('default').to('deprecated')
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

        create(:npm_package, project: project, name: package_name, version: '1.0.5')
        create(:npm_package, project: project, name: package_name, version: '1.0.6')
        params['versions'].merge!(build_params(['1.0.5', '1.0.6'])['versions'])

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

    context 'when package version is not in payload' do
      let(:params) { build_params([package_1.version]) }

      it 'skips packages not in the payload', :aggregate_failures do
        expect { execute }
          .to change {
                package_1.reload.npm_metadatum.package_json['deprecated']
              }.to('This version is deprecated')
          .and not_change { ::Packages::Npm::Metadatum.where(package_id: package_4.id).count }.from(0)
        expect(execute).to be_success
      end
    end

    context 'when handling empty string deprecation' do
      let(:params) { build_params({ package_1.version => '' }) }

      before do
        package_json = package_1.npm_metadatum.package_json
        package_1.npm_metadatum.update_column(:package_json,
          package_json.merge('deprecated' => ''))
      end

      it 'treats empty string and empty string as identical', :aggregate_failures do
        expect { execute }
          .to not_change { package_1.reload.npm_metadatum.package_json.key?('deprecated') }
          .and not_change { package_1.status }.from('default')
        expect(execute).to be_success
      end
    end

    context 'when a version payload is missing the deprecated field' do
      let(:params) do
        build_params([package_1.version]).tap do |p|
          # Add a version entry without the 'deprecated' key
          p['versions'][package_2.version] = {
            'name' => package_name,
            'version' => package_2.version,
            'dist' => {
              'tarball' => 'http://localhost/tarball.tgz',
              'shasum' => '1234567890'
            }
          }
        end
      end

      it 'skips versions missing the deprecated field', :aggregate_failures do
        expect { execute }
          .to change {
                package_1.reload.npm_metadatum.package_json['deprecated']
              }.to('This version is deprecated')
          .and change { package_1.status }.from('default').to('deprecated')
          .and not_change { package_2.reload.npm_metadatum.package_json }
          .and not_change { package_2.status }.from('default')
        expect(execute).to be_success
      end
    end
  end

  def build_params(versions_input, deprecation_msg = 'This version is deprecated')
    # Support both array of versions (with single message) and hash of version => message
    versions_with_msgs =
      if versions_input.is_a?(Hash)
        versions_input
      else
        versions_input.index_with { deprecation_msg }
      end

    {
      'name' => package_name,
      'versions' => versions_with_msgs.to_h do |version, msg|
        [version, {
          'name' => package_name,
          'version' => version,
          'deprecated' => msg,
          'dist' => {
            'tarball' => 'http://localhost/tarball.tgz',
            'shasum' => '1234567890'
          }
        }]
      end
    }
  end
end
