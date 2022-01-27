# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Exporter::WebExporter do
  let(:exporter) { described_class.new }

  before do
    stub_config(
      monitoring: {
        web_exporter: {
          enabled: true,
          port: 0,
          address: '127.0.0.1'
        }
      }
    )

    exporter.start
  end

  after do
    exporter.stop
  end

  context 'when running server', :prometheus do
    it 'initializes request metrics' do
      expect(Gitlab::Metrics::RailsSlis).to receive(:initialize_request_slis_if_needed!).and_call_original

      http = Net::HTTP.new(exporter.server.config[:BindAddress], exporter.server.config[:Port])
      response = http.request(Net::HTTP::Get.new('/metrics'))

      expect(response.body).to include('gitlab_sli:rails_request_apdex')
    end
  end
end
