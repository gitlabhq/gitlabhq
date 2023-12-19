# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::ProcessRunnerVersionUpdateService, feature_category: :fleet_visibility do
  subject(:service) { described_class.new(version) }

  let(:version) { '1.0.0' }
  let(:available_runner_releases) { %w[1.0.0 1.0.1] }

  describe '#execute' do
    subject(:execute) { service.execute }

    context 'with upgrade check returning error' do
      let(:service_double) { instance_double(Gitlab::Ci::RunnerUpgradeCheck) }

      before do
        allow(service_double).to receive(:check_runner_upgrade_suggestion).with(version)
          .and_return([version, :error])
        allow(service).to receive(:upgrade_check_service).and_return(service_double)
      end

      it 'does not update ci_runner_versions records', :aggregate_failures do
        expect do
          expect(execute).to be_error
          expect(execute.message).to eq 'upgrade version check failed'
        end.not_to change(Ci::RunnerVersion, :count).from(0)
        expect(service_double).to have_received(:check_runner_upgrade_suggestion).with(version).once
      end
    end

    context 'when fetching runner releases is disabled' do
      before do
        stub_application_setting(update_runner_versions_enabled: false)
      end

      it 'does not update ci_runner_versions records', :aggregate_failures do
        expect do
          expect(execute).to be_error
          expect(execute.message).to eq 'version update disabled'
        end.not_to change(Ci::RunnerVersion, :count).from(0)
      end
    end

    context 'with successful result from upgrade check' do
      before do
        url = ::Gitlab::CurrentSettings.current_application_settings.public_runner_releases_url

        WebMock.stub_request(:get, url).to_return(
          body: available_runner_releases.map { |v| { name: v } }.to_json,
          status: 200,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      context 'with no existing ci_runner_version record' do
        it 'creates ci_runner_versions record', :aggregate_failures do
          expect do
            expect(execute).to be_success
            expect(execute.http_status).to eq :ok
            expect(execute.payload).to eq({ upgrade_status: 'recommended' })
          end.to change(Ci::RunnerVersion, :all).to contain_exactly(
            an_object_having_attributes(version: version, status: 'recommended')
          )
        end
      end

      context 'with existing ci_runner_version record' do
        let!(:runner_version) { create(:ci_runner_version, version: '1.0.0', status: :unavailable) }

        it 'updates ci_runner_versions record', :aggregate_failures do
          expect do
            expect(execute).to be_success
            expect(execute.http_status).to eq :ok
            expect(execute.payload).to eq({ upgrade_status: 'recommended' })
          end.to change { runner_version.reload.status }.from('unavailable').to('recommended')
        end
      end

      context 'with up-to-date ci_runner_version record' do
        let!(:runner_version) { create(:ci_runner_version, version: '1.0.0', status: :recommended) }

        it 'does not update ci_runner_versions record', :aggregate_failures do
          expect do
            expect(execute).to be_success
            expect(execute.http_status).to eq :ok
            expect(execute.payload).to eq({ upgrade_status: 'recommended' })
          end.not_to change { runner_version.reload.status }
        end
      end
    end
  end
end
