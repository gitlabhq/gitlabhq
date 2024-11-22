# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::EnqueueDeprecatePackageWorkerService, feature_category: :package_registry do
  describe '#execute', :aggregate_failures do
    let(:project) { build_stubbed(:project) }
    let(:package_name) { 'test-package' }

    let(:params) do
      {
        'id' => project.id.to_s,
        'package_name' => package_name,
        'versions' => {
          '1.0.1' => {
            'name' => package_name,
            'deprecated' => 'This version is deprecated'
          },
          '1.0.2' => {
            'name' => package_name
          }
        }
      }
    end

    let(:deprecated_versions) do
      params.deep_dup.tap { |p| p['versions'].slice!('1.0.1') }
    end

    subject(:response) { described_class.new(project, nil, params).execute }

    it 'enqueues deprecate npm package worker' do
      expect(::Packages::Npm::DeprecatePackageWorker).to receive(:perform_async).with(project.id, deprecated_versions)

      expect(response).to be_success
    end

    context 'when no versions to deprecate' do
      let(:params) do
        super().tap { |p| p['versions'].slice!('1.0.2') }
      end

      it 'does not enqueue deprecate npm package worker' do
        expect(::Packages::Npm::DeprecatePackageWorker).not_to receive(:perform_async)

        expect(response).to be_error
        expect(response.message).to eq('no versions to deprecate')
        expect(response.reason).to eq(:no_versions_to_deprecate)
      end
    end
  end
end
