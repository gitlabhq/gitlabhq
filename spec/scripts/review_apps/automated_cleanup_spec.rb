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
  let(:ten_days_ago)      { (now - (10 * 24 * 3600)) }

  before do
    allow(instance).to receive(:gitlab).and_return(gitlab_client)
    allow(Time).to receive(:now).and_return(now)
    allow(Tooling::Helm3Client).to receive(:new).and_return(helm_client)
    allow(Tooling::KubernetesClient).to receive(:new).and_return(kubernetes_client)

    allow(kubernetes_client).to receive(:cleanup_namespaces_by_created_at)
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

  describe '.parse_args' do
    subject { described_class.parse_args(argv) }

    context 'when no arguments are provided' do
      let(:argv) { %w[] }

      it 'returns the default options' do
        expect(subject).to eq(dry_run: false)
      end
    end

    describe '--dry-run' do
      context 'when no DRY_RUN variable is provided' do
        let(:argv) { ['--dry-run='] }

        # This is the default behavior of OptionParser.
        # We should always pass an environment variable with a value, or not pass the flag at all.
        it 'raises an error' do
          expect { subject }.to raise_error(OptionParser::InvalidArgument, 'invalid argument: --dry-run=')
        end
      end

      context 'when the DRY_RUN variable is not set to true' do
        let(:argv) { %w[--dry-run=false] }

        it 'returns the default options' do
          expect(subject).to eq(dry_run: false)
        end
      end

      context 'when the DRY_RUN variable is set to true' do
        let(:argv) { %w[--dry-run=true] }

        it 'returns the correct dry_run value' do
          expect(subject).to eq(dry_run: true)
        end
      end

      context 'when the short version of the flag is used' do
        let(:argv) { %w[-d true] }

        it 'returns the correct dry_run value' do
          expect(subject).to eq(dry_run: true)
        end
      end
    end
  end

  describe '#perform_stale_namespace_cleanup!' do
    subject { instance.perform_stale_namespace_cleanup!(days: days) }

    let(:days) { 2 }

    it_behaves_like 'the days argument is an integer in the correct range'

    it 'performs Kubernetes cleanup for review apps namespaces' do
      expect(kubernetes_client).to receive(:cleanup_namespaces_by_created_at).with(created_before: two_days_ago)

      subject
    end

    context 'when the dry-run flag is true' do
      let(:dry_run) { true }

      it 'does not delete anything' do
        expect(kubernetes_client).not_to receive(:cleanup_namespaces_by_created_at)
      end
    end
  end

  describe '#perform_gitlab_environment_cleanup!' do
    let(:env_prefix) { 'test-prefix/' }
    let(:days_for_delete) { 2 }
    let(:environment_created_at) { two_days_ago.to_s }
    let(:env_name)  { "#{env_prefix}an-env-name" }
    let(:env_state) { 'available' }
    # rubocop:disable RSpec/VerifiedDoubles -- Internal API resource
    let(:environments) do
      [double('GitLab Environment',
        id: env_name,
        name: env_name,
        slug: env_name,
        state: env_state,
        created_at: environment_created_at)]
    end

    subject do
      instance.perform_gitlab_environment_cleanup!(
        env_prefix: env_prefix,
        days_for_delete: days_for_delete
      )
    end

    before do
      allow(gitlab_client).to yield_environments(:environments, environments)

      # Silence outputs to stdout
      allow(instance).to receive(:puts)
    end

    def yield_environments(api_method, environments)
      messages = receive_message_chain(api_method, :auto_paginate)

      environments.inject(messages) do |stub, environment|
        stub.and_yield(environment)
      end
    end

    # rubocop:enable RSpec/VerifiedDoubles -- Internal API resource

    context 'when the environment is not for a review-app' do
      let(:env_name) { 'not-for-a-review-app' }

      it 'does not stop the environment' do
        expect(gitlab_client).not_to receive(:stop_environment)

        subject
      end

      it 'does not delete the environment' do
        expect(gitlab_client).not_to receive(:delete_environment)

        subject
      end
    end

    context 'when the environment is for a review-app' do
      context 'when the environment state is stopping' do
        let(:env_state) { 'stopping' }

        it 'does not stop the environment' do
          expect(gitlab_client).not_to receive(:stop_environment)

          subject
        end

        it 'does not delete the environment' do
          expect(gitlab_client).not_to receive(:delete_environment)

          subject
        end
      end

      context 'when the environment was created later than the days_for_delete argument' do
        let(:environment_created_at) { one_day_ago.to_s }

        it 'does not stop the environment' do
          expect(gitlab_client).not_to receive(:stop_environment)

          subject
        end

        it 'does not delete the environment' do
          expect(gitlab_client).not_to receive(:delete_environment)

          subject
        end
      end

      context 'when the environment was created earlier than the days_for_delete argument' do
        let(:environment_created_at) { three_days_ago.to_s }

        it 'stops the environment' do
          expect(gitlab_client).to receive(:stop_environment)
          allow(gitlab_client).to receive(:delete_environment)

          subject
        end

        it 'deletes the environment' do
          allow(gitlab_client).to receive(:stop_environment)
          expect(gitlab_client).to receive(:delete_environment)

          subject
        end
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
        allow(kubernetes_client).to receive(:delete_namespaces)
      end

      it 'deletes the helm release' do
        expect(helm_client).to receive(:delete).with(release_name: releases_names)

        subject
      end

      it 'deletes the associated k8s namespace' do
        expect(kubernetes_client).to receive(:delete_namespaces).with(releases_names)

        subject
      end
    end

    shared_examples 'does not delete the helm release' do
      it 'does not delete the helm release' do
        expect(helm_client).not_to receive(:delete)

        subject
      end

      it 'does not delete the associated k8s namespace' do
        expect(kubernetes_client).not_to receive(:delete_namespaces)

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
