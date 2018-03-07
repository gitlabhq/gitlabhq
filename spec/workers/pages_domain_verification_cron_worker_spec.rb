require 'spec_helper'

describe PagesDomainVerificationCronWorker do
  subject(:worker) { described_class.new }

  describe '#perform' do
    it 'enqueues a PagesDomainVerificationWorker for domains needing verification' do
      verified = create(:pages_domain)
      reverify = create(:pages_domain, :reverify)
      disabled = create(:pages_domain, :disabled)

      [reverify, disabled].each do |domain|
        expect(PagesDomainVerificationWorker).to receive(:perform_async).with(domain.id)
      end

      expect(PagesDomainVerificationWorker).not_to receive(:perform_async).with(verified.id)

      worker.perform
    end
  end
end
