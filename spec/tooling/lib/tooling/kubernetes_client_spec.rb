# frozen_string_literal: true

require 'time'
require_relative '../../../../tooling/lib/tooling/kubernetes_client'

RSpec.describe Tooling::KubernetesClient do
  let(:instance)       { described_class.new }
  let(:one_day_ago)    { Time.now - (3600 * 24 * 1) }
  let(:two_days_ago)   { Time.now - (3600 * 24 * 2) }
  let(:three_days_ago) { Time.now - (3600 * 24 * 3) }

  before do
    # Global mock to ensure that no kubectl commands are run by accident in a test.
    allow(instance).to receive(:run_command)
  end

  describe '#cleanup_namespaces_by_created_at' do
    let(:namespace_1_created_at) { three_days_ago }
    let(:namespace_2_created_at) { three_days_ago }
    let(:namespace_1_name) { 'review-first-review-app' }
    let(:namespace_2_name) { 'review-second-review-app' }
    let(:kubectl_namespaces_json) do
      <<~JSON
        {
          "apiVersion": "v1",
          "items": [
              {
                  "apiVersion": "v1",
                  "kind": "namespace",
                  "metadata": {
                      "creationTimestamp": "#{namespace_1_created_at.utc.iso8601}",
                      "name": "#{namespace_1_name}"
                  }
              },
              {
                  "apiVersion": "v1",
                  "kind": "namespace",
                  "metadata": {
                      "creationTimestamp": "#{namespace_2_created_at.utc.iso8601}",
                      "name": "#{namespace_2_name}"
                  }
              }
          ]
        }
      JSON
    end

    subject { instance.cleanup_namespaces_by_created_at(created_before: two_days_ago) }

    before do
      allow(instance).to receive(:run_command).with([
        'kubectl',
        'get',
        'namespace',
        '--all-namespaces',
        '--sort-by',
        '{.metadata.creationTimestamp}',
        '-o',
        'json'
      ]).and_return(kubectl_namespaces_json)
    end

    context 'when no namespaces are stale' do
      let(:namespace_1_created_at) { one_day_ago }
      let(:namespace_2_created_at) { one_day_ago }

      it 'does not delete any namespace' do
        expect(instance).not_to receive(:run_command).with(/kubectl delete namespace/)

        subject
      end
    end

    context 'when some namespaces are stale' do
      let(:namespace_1_created_at) { three_days_ago }
      let(:namespace_2_created_at) { three_days_ago }

      context 'when some namespaces are not review app namespaces' do
        let(:namespace_1_name) { 'review-my-review-app' }
        let(:namespace_2_name) { 'review-apps' } # This is not a review apps namespace, so we should not try to delete it

        it 'only deletes the review app namespaces' do
          expect(instance).to receive(:run_command).with(
            %W[kubectl delete namespace --now --ignore-not-found #{namespace_1_name}]
          )
          subject
        end
      end

      context 'when all namespaces are review app namespaces' do
        let(:namespace_1_name) { 'review-my-review-app' }
        let(:namespace_2_name) { 'review-another-review-app' }

        it 'deletes all of the stale namespaces' do
          namespaces = [namespace_1_name, namespace_2_name].join(' ')
          expect(instance).to receive(:run_command).with(
            %W[kubectl delete namespace --now --ignore-not-found #{namespaces}]
          )
          subject
        end
      end
    end
  end

  describe '#delete_namespaces' do
    subject { instance.delete_namespaces(namespaces) }

    context 'when at least one namespace is not a review app namespace' do
      let(:namespaces) { %w[review-ns-1 default] }

      it 'does not delete any namespace' do
        expect(instance).not_to receive(:run_command).with(/kubectl delete namespace/)

        subject
      end
    end

    context 'when all namespaces are review app namespaces' do
      let(:namespaces) { %w[review-ns-1 review-ns-2] }

      it 'deletes the namespaces' do
        expect(instance).to receive(:run_command).with(
          %W[kubectl delete namespace --now --ignore-not-found #{namespaces.join(' ')}]
        )

        subject
      end
    end
  end

  describe '#namespaces_created_before' do
    subject { instance.namespaces_created_before(created_before: two_days_ago) }

    let(:namespace_1_created_at) { three_days_ago }
    let(:namespace_2_created_at) { one_day_ago }
    let(:namespace_1_name) { 'review-first-review-app' }
    let(:namespace_2_name) { 'review-second-review-app' }
    let(:kubectl_namespaces_json) do
      <<~JSON
        {
          "apiVersion": "v1",
          "items": [
              {
                  "apiVersion": "v1",
                  "kind": "namespace",
                  "metadata": {
                      "creationTimestamp": "#{namespace_1_created_at.utc.iso8601}",
                      "name": "#{namespace_1_name}"
                  }
              },
              {
                  "apiVersion": "v1",
                  "kind": "namespace",
                  "metadata": {
                      "creationTimestamp": "#{namespace_2_created_at.utc.iso8601}",
                      "name": "#{namespace_2_name}"
                  }
              }
          ]
        }
      JSON
    end

    it 'returns an array of namespaces' do
      allow(instance).to receive(:run_command).with([
        'kubectl',
        'get',
        'namespace',
        '--all-namespaces',
        '--sort-by',
        '{.metadata.creationTimestamp}',
        '-o',
        'json'
      ]).and_return(kubectl_namespaces_json)

      expect(subject).to match_array(%w[review-first-review-app])
    end
  end

  describe '#run_command' do
    subject { instance.run_command(command) }

    before do
      # We undo the global mock just for this method
      allow(instance).to receive(:run_command).and_call_original

      # Mock stdout
      allow(instance).to receive(:puts)
    end

    context 'when executing a successful command' do
      let(:command) { ['true'] } # https://linux.die.net/man/1/true

      it 'displays the name of the command to stdout' do
        expect(instance).to receive(:puts).with("Running command: `#{command.join(' ')}`")

        subject
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when executing an unsuccessful command' do
      let(:command) { ['false'] } # https://linux.die.net/man/1/false

      it 'displays the name of the command to stdout' do
        expect(instance).to receive(:puts).with("Running command: `#{command.join(' ')}`")

        expect { subject }.to raise_error(described_class::CommandFailedError)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::CommandFailedError)
      end
    end
  end
end
