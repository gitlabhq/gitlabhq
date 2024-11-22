# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::DeprecatePackageWorker, feature_category: :package_registry do
  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let(:worker) { described_class.new }
    let(:params) do
      {
        'package_name' => 'package_name',
        'versions' => {
          '1.0.1' => {
            'name' => 'package_name',
            'deprecated' => 'This version is deprecated'
          }
        }
      }
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [project.id, params] }

      it 'calls the deprecation service' do
        expect(::Packages::Npm::DeprecatePackageService).to receive(:new).with(project, params) do
          double.tap do |service|
            expect(service).to receive(:execute)
          end
        end

        worker.perform(*job_args)
      end
    end
  end
end
