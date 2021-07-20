# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Helpers::Runner do
  let(:ip_address) { '1.2.3.4' }
  let(:runner_class) do
    Class.new do
      include API::Helpers
      include API::Ci::Helpers::Runner

      attr_accessor :params

      def initialize(params)
        @params = params
      end

      def ip_address
        '1.2.3.4'
      end
    end
  end

  let(:runner_helper) { runner_class.new(runner_params) }

  describe '#get_runner_details_from_request' do
    context 'when no runner info is present' do
      let(:runner_params) { {} }

      it 'returns the runner IP' do
        expect(runner_helper.get_runner_details_from_request).to eq({ ip_address: ip_address })
      end
    end

    context 'when runner info is present' do
      let(:name) { 'runner' }
      let(:version) { '1.2.3' }
      let(:revision) { '10.0' }
      let(:platform) { 'test' }
      let(:architecture) { 'arm' }
      let(:config) { { 'gpus' => 'all' } }
      let(:runner_params) do
        {
          'info' =>
          {
            'name' => name,
            'version' => version,
            'revision' => revision,
            'platform' => platform,
            'architecture' => architecture,
            'config' => config,
            'ignored' => 1
          }
        }
      end

      subject(:details) { runner_helper.get_runner_details_from_request }

      it 'extracts the runner details', :aggregate_failures do
        expect(details.keys).to match_array(%w(name version revision platform architecture config ip_address))
        expect(details['name']).to eq(name)
        expect(details['version']).to eq(version)
        expect(details['revision']).to eq(revision)
        expect(details['platform']).to eq(platform)
        expect(details['architecture']).to eq(architecture)
        expect(details['config']).to eq(config)
        expect(details['ip_address']).to eq(ip_address)
      end
    end
  end
end
