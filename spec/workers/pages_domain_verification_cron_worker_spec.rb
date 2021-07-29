# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDomainVerificationCronWorker do
  subject(:worker) { described_class.new }

  describe '#perform', :sidekiq do
    let!(:verified) { create(:pages_domain) }
    let!(:reverify) { create(:pages_domain, :reverify, :with_project) }
    let!(:disabled) { create(:pages_domain, :disabled) }

    it 'does nothing if the database is read-only' do
      allow(Gitlab::Database.main).to receive(:read_only?).and_return(true)
      expect(PagesDomainVerificationWorker).not_to receive(:perform_async).with(reverify.id)

      worker.perform
    end

    it 'enqueues a PagesDomainVerificationWorker for domains needing verification' do
      [reverify, disabled].each do |domain|
        expect(PagesDomainVerificationWorker).to receive(:perform_async).with(domain.id)
      end

      expect(PagesDomainVerificationWorker).not_to receive(:perform_async).with(verified.id)

      worker.perform
    end

    it_behaves_like 'a pages cronjob scheduling jobs with context', PagesDomainVerificationWorker do
      let(:extra_domain) { create(:pages_domain, :reverify, :with_project) }
    end
  end
end
