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

  let(:service) { described_class.new(project, params) }

  subject(:execute) { service.execute }

  describe '#execute' do
    context 'when passing deprecatation message' do
      let(:params) do
        {
          'package_name' => package_name,
          'versions' => {
            '1.0.1' => {
              'name' => package_name,
              'deprecated' => 'This version is deprecated'
            },
            '1.0.2' => {
              'name' => package_name,
              'deprecated' => 'This version is deprecated'
            }
          }
        }
      end

      before do
        package_json = package_2.npm_metadatum.package_json
        package_2.npm_metadatum.update!(package_json: package_json.merge('deprecated' => 'old deprecation message'))
      end

      it 'adds or updates the deprecated field' do
        expect { execute }
          .to change { package_1.reload.npm_metadatum.package_json['deprecated'] }.to('This version is deprecated')
          .and change { package_2.reload.npm_metadatum.package_json['deprecated'] }
            .from('old deprecation message').to('This version is deprecated')
      end

      it 'executes 5 queries' do
        queries = ActiveRecord::QueryRecorder.new do
          execute
        end

        # 1. each_batch lower bound
        # 2. each_batch upper bound
        # 3. SELECT packages_packages.id, packages_packages.version FROM packages_packages
        # 4. SELECT packages_npm_metadata.* FROM packages_npm_metadata
        # 5. UPDATE packages_npm_metadata SET package_json =
        expect(queries.count).to eq(5)
      end
    end

    context 'when passing deprecated as empty string' do
      let(:params) do
        {
          'package_name' => package_name,
          'versions' => {
            '1.0.1' => {
              'name' => package_name,
              'deprecated' => ''
            }
          }
        }
      end

      before do
        package_json = package_1.npm_metadatum.package_json
        package_1.npm_metadatum.update!(package_json: package_json.merge('deprecated' => 'This version is deprecated'))
      end

      it 'removes the deprecation warning' do
        expect { execute }
          .to change { package_1.reload.npm_metadatum.package_json['deprecated'] }
            .from('This version is deprecated').to(nil)
      end
    end

    context 'when passing async: true to execute' do
      let(:params) do
        {
          package_name: package_name,
          versions: {
            '1.0.1': {
              deprecated: 'This version is deprecated'
            }
          }
        }
      end

      it 'calls the worker and return' do
        expect(::Packages::Npm::DeprecatePackageWorker).to receive(:perform_async).with(project.id, params)
        expect(service).not_to receive(:packages)

        service.execute(async: true)
      end
    end
  end
end
