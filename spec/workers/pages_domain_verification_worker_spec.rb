# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDomainVerificationWorker, feature_category: :pages do
  subject(:worker) { described_class.new }

  let(:domain) { create(:pages_domain) }

  describe '#perform' do
    it 'does nothing if the database is read-only' do
      allow(Gitlab::Database).to receive(:read_only?).and_return(true)
      expect(PagesDomain).not_to receive(:find_by).with(id: domain.id)

      worker.perform(domain.id)
    end

    it 'does nothing for a non-existent domain' do
      domain.destroy!

      expect(VerifyPagesDomainService).not_to receive(:new)

      expect { worker.perform(domain.id) }.not_to raise_error
    end

    it 'delegates to VerifyPagesDomainService' do
      service = double(:service)
      expected_domain = satisfy { |obj| obj == domain }

      expect(VerifyPagesDomainService).to receive(:new).with(expected_domain) { service }
      expect(service).to receive(:execute)

      worker.perform(domain.id)
    end
  end
end
