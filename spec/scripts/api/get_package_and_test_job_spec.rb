# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'fast_spec_helper'
require_relative '../../../scripts/api/get_package_and_test_job'

RSpec.describe GetPackageAndTestJob, feature_category: :tooling do
  describe '#execute' do
    let(:options) do
      {
        api_token: 'token',
        endpoint: 'https://example.gitlab.com',
        project: 12345,
        pipeline_id: 1
      }
    end

    let(:client) { double('Gitlab::Client') }
    let(:client_response) { double('Gitlab::ClientResponse') }
    let(:bridge_status) { 'success' }

    let(:bridges_response) do
      [
        double(:bridge, id: 1, name: 'foo'),
        double(:bridge, id: 2, name: 'bar'),
        double(
          :bridge,
          id: 3,
          name: 'e2e:package-and-test-ee',
          downstream_pipeline: double(:downstream_pipeline, id: 1),
          status: bridge_status
        )
      ]
    end

    let(:detailed_status_label) { 'passed with warnings' }

    let(:package_and_test_pipeline) do
      double(
        :pipeline,
        id: 1,
        name: 'e2e:package-and-test-ee',
        detailed_status: double(
          :detailed_status,
          text: 'passed',
          label: detailed_status_label
        )
      )
    end

    before do
      allow(Gitlab)
        .to receive(:client)
        .and_return(client)

      allow(client)
        .to receive(:pipeline_bridges)
        .and_return(double(auto_paginate: bridges_response))

      allow(client)
        .to receive(:pipeline)
        .and_return(package_and_test_pipeline)
    end

    subject { described_class.new(options).execute }

    it 'returns a package-and-test pipeline that passed with warnings' do
      expect(subject).to eq(package_and_test_pipeline)
    end

    context 'when the bridge can not be found' do
      let(:bridges_response) { [] }

      it 'returns nothing' do
        expect(subject).to be_nil
      end
    end

    context 'when the downstream pipeline can not be found' do
      let(:bridges_response) do
        [
          double(:bridge, id: 1, name: 'foo'),
          double(:bridge, id: 2, name: 'bar'),
          double(
            :bridge,
            id: 3,
            name: 'e2e:package-and-test-ee',
            downstream_pipeline: nil
          )
        ]
      end

      it 'returns nothing' do
        expect(subject).to be_nil
      end
    end

    context 'when the bridge fails' do
      let(:bridge_status) { 'failed' }

      it 'returns the downstream_pipeline' do
        expect(subject).to eq(package_and_test_pipeline)
      end
    end

    context 'when the package-and-test can not be found' do
      let(:package_and_test_pipeline) { nil }

      it 'returns nothing' do
        expect(subject).to be_nil
      end
    end

    context 'when the package-and-test does not include a detailed status' do
      let(:package_and_test_pipeline) do
        double(
          :pipeline,
          name: 'e2e:package-and-test-ee',
          detailed_status: nil
        )
      end

      it 'returns nothing' do
        expect(subject).to be_nil
      end
    end

    context 'when the package-and-test succeeds' do
      let(:detailed_status_label) { 'passed' }

      it 'returns nothing' do
        expect(subject).to be_nil
      end
    end

    context 'when the package-and-test is canceled' do
      let(:detailed_status_label) { 'canceled' }

      it 'returns a failed package-and-test pipeline' do
        expect(subject).to eq(package_and_test_pipeline)
      end
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles
