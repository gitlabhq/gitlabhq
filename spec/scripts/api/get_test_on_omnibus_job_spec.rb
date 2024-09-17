# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles -- simplify mocking gitlab client response objects

require 'fast_spec_helper'
require_relative '../../../scripts/api/get_test_on_omnibus_job'

RSpec.describe GetTestOnOmnibusJob, feature_category: :tooling do
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
          name: 'e2e:test-on-omnibus-ee',
          downstream_pipeline: double(:downstream_pipeline, id: 1),
          status: bridge_status
        )
      ]
    end

    let(:detailed_status_label) { 'passed with warnings' }

    let(:test_on_omnibus_pipeline) do
      double(
        :pipeline,
        id: 1,
        name: 'e2e:test-on-omnibus-ee',
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
        .and_return(test_on_omnibus_pipeline)
    end

    subject(:test_on_omnibus_job) { described_class.new(options).execute }

    it 'returns a test-on-omnibus pipeline that passed with warnings' do
      expect(test_on_omnibus_job).to eq(test_on_omnibus_pipeline)
    end

    context 'when the bridge can not be found' do
      let(:bridges_response) { [] }

      it 'returns nothing' do
        expect(test_on_omnibus_job).to be_nil
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
            name: 'e2e:test-on-omnibus-ee',
            downstream_pipeline: nil
          )
        ]
      end

      it 'returns nothing' do
        expect(test_on_omnibus_job).to be_nil
      end
    end

    context 'when the bridge fails' do
      let(:bridge_status) { 'failed' }

      it 'returns the downstream_pipeline' do
        expect(test_on_omnibus_job).to eq(test_on_omnibus_pipeline)
      end
    end

    context 'when the test-on-omnibus can not be found' do
      let(:test_on_omnibus_pipeline) { nil }

      it 'returns nothing' do
        expect(test_on_omnibus_job).to be_nil
      end
    end

    context 'when the test-on-omnibus does not include a detailed status' do
      let(:test_on_omnibus_pipeline) do
        double(
          :pipeline,
          name: 'e2e:test-on-omnibus-ee',
          detailed_status: nil
        )
      end

      it 'returns nothing' do
        expect(test_on_omnibus_job).to be_nil
      end
    end

    context 'when the test-on-omnibus succeeds' do
      let(:detailed_status_label) { 'passed' }

      it 'returns nothing' do
        expect(test_on_omnibus_job).to be_nil
      end
    end

    context 'when the test-on-omnibus is canceled' do
      let(:detailed_status_label) { 'canceled' }

      it 'returns a failed test-on-omnibus pipeline' do
        expect(test_on_omnibus_job).to eq(test_on_omnibus_pipeline)
      end
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles
