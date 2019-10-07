# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::HealthChecks::Probes::Liveness do
  let(:liveness) { described_class.new }

  describe '#call' do
    subject { liveness.execute }

    it 'responds with liveness checks data' do
      expect(subject.http_status).to eq(200)

      expect(subject.json[:status]).to eq('ok')
    end
  end
end
