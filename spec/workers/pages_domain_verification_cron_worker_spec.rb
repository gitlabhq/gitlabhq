# frozen_string_literal: true

require 'spec_helper'

describe PagesDomainVerificationCronWorker do
  subject(:worker) { described_class.new }

  describe '#perform' do
    let!(:verified) { create(:pages_domain) }
    let!(:reverify) { create(:pages_domain, :reverify) }
    let!(:disabled) { create(:pages_domain, :disabled) }

    it 'enqueues a PagesDomainVerificationWorker for domains needing verification' do
      [reverify, disabled].each do |domain|
        expect(PagesDomainVerificationWorker).to receive(:perform_async).with(domain.id)
      end

      expect(PagesDomainVerificationWorker).not_to receive(:perform_async).with(verified.id)

      worker.perform
    end
  end
end
