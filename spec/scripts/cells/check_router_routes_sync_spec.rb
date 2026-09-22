# frozen_string_literal: true

require 'fast_spec_helper'
require 'webmock/rspec'

require_relative '../../../scripts/cells/check_router_routes_sync'

RSpec.describe CheckRouterRoutesSync, feature_category: :tooling do
  let(:snapshot_url) do
    'https://gitlab.com/api/v4/projects/gitlab-org%2Fcells%2Fhttp-router' \
      '/repository/files/test%2Froutes%2Fgitlab_routes.json/raw?ref=main'
  end

  let(:env)            { {} }
  let(:local_payload)  { payload }
  let(:router_payload) { local_payload }

  # SnapshotComparison::MIN_ROUTES rejects a short payload as a truncated
  # response, so pad each snapshot up to the floor.
  def payload
    routes = Array.new(Gitlab::Cells::HttpRouter::SnapshotComparison::MIN_ROUTES) do |i|
      { 'template' => "/filler/#{i}", 'example' => "/filler/#{i}" }
    end

    "#{JSON.pretty_generate(routes)}\n" # rubocop:disable Gitlab/Json -- the script runs on plain Ruby, outside Rails
  end

  before do
    stub_const('ENV', env)
    described_class.instance_variable_set(:@snapshot_url, nil)

    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(described_class.send(:local_path)).and_return(local_payload)

    stub_request(:get, snapshot_url).to_return(status: 200, body: router_payload)
  end

  describe '.run' do
    it 'downloads the router snapshot and reports it in sync' do
      expect { expect(described_class.run).to eq(described_class::IN_SYNC) }
        .to output(include("matches #{described_class::LOCAL_SNAPSHOT}")).to_stdout

      expect(a_request(:get, snapshot_url)).to have_been_made
    end

    context 'when CI_JOB_TOKEN is set' do
      let(:env) { { 'CI_JOB_TOKEN' => 'glcbt-test-token' } }

      it 'sends the JOB-TOKEN header with the download request' do
        expect { described_class.run }.to output.to_stdout

        expect(a_request(:get, snapshot_url).with(headers: { 'JOB-TOKEN' => 'glcbt-test-token' }))
          .to have_been_made
      end
    end

    context 'when CI_JOB_TOKEN is not set' do
      it 'omits the JOB-TOKEN header' do
        expect { described_class.run }.to output.to_stdout

        expect(a_request(:get, snapshot_url).with { |request| request.headers.key?('Job-Token') })
          .not_to have_been_made
      end
    end
  end
end
