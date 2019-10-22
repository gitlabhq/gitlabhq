# frozen_string_literal: true

require 'spec_helper'

describe Deployments::UpdateService do
  let(:deploy) { create(:deployment, :running) }
  let(:service) { described_class.new(deploy, status: 'success') }

  describe '#execute' do
    it 'updates the status of a deployment' do
      expect(service.execute).to eq(true)
      expect(deploy.status).to eq('success')
    end
  end
end
