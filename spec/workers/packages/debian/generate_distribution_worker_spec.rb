# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::GenerateDistributionWorker, type: :worker do
  describe '#perform' do
    let(:container_type) { distribution.container_type }
    let(:distribution_id) { distribution.id }

    subject { described_class.new.perform(container_type, distribution_id) }

    include_context 'with published Debian package'

    [:project, :group].each do |container_type|
      context "for #{container_type}" do
        include_context 'with Debian distribution', container_type

        context 'with mocked service' do
          it 'calls GenerateDistributionService' do
            expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
            expect_next_instance_of(::Packages::Debian::GenerateDistributionService) do |service|
              expect(service).to receive(:execute)
                .with(no_args)
            end

            subject
          end
        end

        context 'with non existing distribution id' do
          let(:distribution_id) { non_existing_record_id }

          it 'returns early without error' do
            expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
            expect(::Packages::Debian::GenerateDistributionService).not_to receive(:new)

            subject
          end
        end

        context 'with nil distribution id' do
          let(:distribution_id) { nil }

          it 'returns early without error' do
            expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
            expect(::Packages::Debian::GenerateDistributionService).not_to receive(:new)

            subject
          end
        end

        context 'with valid parameters' do
          it_behaves_like 'an idempotent worker' do
            let(:job_args) { [container_type, distribution_id] }

            it_behaves_like 'Generate Debian Distribution and component files'
          end
        end
      end
    end
  end
end
