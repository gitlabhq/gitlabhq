# frozen_string_literal: true

require 'fast_spec_helper'
require 'time'
require_relative '../../../scripts/review_apps/automated_cleanup'

RSpec.describe ReviewApps::AutomatedCleanup, feature_category: :tooling do
  let(:instance) { described_class.new(options: options) }
  let(:options) do
    {
      project_path: 'my-project-path',
      gitlab_token: 'glpat-test-secret-token',
      api_endpoint: 'gitlab.test/api/v4',
      dry_run: dry_run
    }
  end

  let(:kubernetes_client) { instance_double(Tooling::KubernetesClient) }
  let(:helm_client)       { instance_double(Tooling::Helm3Client) }
  let(:gitlab_client)     { double('GitLab') } # rubocop:disable RSpec/VerifiedDoubles
  let(:dry_run)           { false }
  let(:now)               { Time.now }
  let(:one_day_ago)       { (now - (1 * 24 * 3600)) }
  let(:two_days_ago)      { (now - (2 * 24 * 3600)) }
  let(:three_days_ago)    { (now - (3 * 24 * 3600)) }

  before do
    allow(instance).to receive(:gitlab).and_return(gitlab_client)
    allow(Time).to receive(:now).and_return(now)
    allow(Tooling::Helm3Client).to receive(:new).and_return(helm_client)
    allow(Tooling::KubernetesClient).to receive(:new).and_return(kubernetes_client)

    allow(kubernetes_client).to receive(:cleanup_by_created_at)
    allow(kubernetes_client).to receive(:cleanup_by_release)
    allow(kubernetes_client).to receive(:cleanup_review_app_namespaces)
    allow(kubernetes_client).to receive(:delete_namespaces_by_exact_names)
  end

  shared_examples 'the days argument is an integer in the correct range' do
    context 'when days is nil' do
      let(:days) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error('days should be an integer between 1 and 365 inclusive! Got 0')
      end
    end

    context 'when days is zero' do
      let(:days) { 0 }

      it 'raises an error' do
        expect { subject }.to raise_error('days should be an integer between 1 and 365 inclusive! Got 0')
      end
    end

    context 'when days is above 365' do
      let(:days) { 366 }

      it 'raises an error' do
        expect { subject }.to raise_error('days should be an integer between 1 and 365 inclusive! Got 366')
      end
    end

    context 'when days is a string' do
      let(:days) { '10' }

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when days is a float' do
      let(:days) { 3.0 }

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe '#perform_stale_pvc_cleanup!' do
    subject { instance.perform_stale_pvc_cleanup!(days: days) }

    let(:days) { 2 }

    it_behaves_like 'the days argument is an integer in the correct range'

    it 'performs Kubernetes cleanup by created at' do
      expect(kubernetes_client).to receive(:cleanup_by_created_at).with(
        resource_type: 'pvc',
        created_before: two_days_ago,
        wait: false
      )

      subject
    end

    context 'when the dry-run flag is true' do
      let(:dry_run) { true }

      it 'does not delete anything' do
        expect(kubernetes_client).not_to receive(:cleanup_by_created_at)
      end
    end
  end

  describe '#perform_stale_namespace_cleanup!' do
    subject { instance.perform_stale_namespace_cleanup!(days: days) }

    let(:days) { 2 }

    it_behaves_like 'the days argument is an integer in the correct range'

    it 'performs Kubernetes cleanup for review apps namespaces' do
      expect(kubernetes_client).to receive(:cleanup_review_app_namespaces).with(
        created_before: two_days_ago,
        wait: false
      )

      subject
    end

    context 'when the dry-run flag is true' do
      let(:dry_run) { true }

      it 'does not delete anything' do
        expect(kubernetes_client).not_to receive(:cleanup_review_app_namespaces)
      end
    end
  end

  describe '#perform_helm_releases_cleanup!' do
    subject { instance.perform_helm_releases_cleanup!(days: days) }

    let(:days) { 2 }
    let(:helm_releases) { [] }

    before do
      allow(helm_client).to receive(:releases).and_return(helm_releases)

      # Silence outputs to stdout
      allow(instance).to receive(:puts)
    end

    shared_examples 'deletes the helm release' do
      let(:releases_names) { helm_releases.map(&:name) }

      before do
        allow(helm_client).to receive(:delete)
        allow(kubernetes_client).to receive(:cleanup_by_release)
        allow(kubernetes_client).to receive(:delete_namespaces_by_exact_names)
      end

      it 'deletes the helm release' do
        expect(helm_client).to receive(:delete).with(release_name: releases_names)

        subject
      end

      it 'empties the k8s resources in the k8s namespace for the release' do
        expect(kubernetes_client).to receive(:cleanup_by_release).with(release_name: releases_names, wait: false)

        subject
      end

      it 'deletes the associated k8s namespace' do
        expect(kubernetes_client).to receive(:delete_namespaces_by_exact_names).with(
          resource_names: releases_names, wait: false
        )

        subject
      end
    end

    shared_examples 'does not delete the helm release' do
      it 'does not delete the helm release' do
        expect(helm_client).not_to receive(:delete)

        subject
      end

      it 'does not empty the k8s resources in the k8s namespace for the release' do
        expect(kubernetes_client).not_to receive(:cleanup_by_release)

        subject
      end

      it 'does not delete the associated k8s namespace' do
        expect(kubernetes_client).not_to receive(:delete_namespaces_by_exact_names)

        subject
      end
    end

    shared_examples 'does nothing on a dry run' do
      it_behaves_like 'does not delete the helm release'
    end

    it_behaves_like 'the days argument is an integer in the correct range'

    context 'when the helm release is not a review-app release' do
      let(:helm_releases) do
        [
          Tooling::Helm3Client::Release.new(
            name: 'review-apps', namespace: 'review-apps', revision: 1, status: 'success', updated: three_days_ago.to_s
          )
        ]
      end

      it_behaves_like 'does not delete the helm release'
    end

    context 'when the helm release is a review-app release' do
      let(:helm_releases) do
        [
          Tooling::Helm3Client::Release.new(
            name: 'review-test', namespace: 'review-test', revision: 1, status: status, updated: updated_at
          )
        ]
      end

      context 'when the helm release was deployed recently enough' do
        let(:updated_at) { one_day_ago.to_s }

        context 'when the helm release is in failed state' do
          let(:status) { 'failed' }

          it_behaves_like 'deletes the helm release'

          context 'when the dry-run flag is true' do
            let(:dry_run) { true }

            it_behaves_like 'does nothing on a dry run'
          end
        end

        context 'when the helm release is not in failed state' do
          let(:status) { 'success' }

          it_behaves_like 'does not delete the helm release'
        end
      end

      context 'when the helm release was deployed a while ago' do
        let(:updated_at) { three_days_ago.to_s }

        context 'when the helm release is in failed state' do
          let(:status) { 'failed' }

          it_behaves_like 'deletes the helm release'
        end

        context 'when the helm release is not in failed state' do
          let(:status) { 'success' }

          it_behaves_like 'deletes the helm release'
        end
      end
    end
  end
end
