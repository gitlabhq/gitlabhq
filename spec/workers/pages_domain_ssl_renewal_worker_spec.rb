# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDomainSslRenewalWorker, feature_category: :pages do
  include LetsEncryptHelpers

  subject(:worker) { described_class.new }

  let(:project) { create(:project) }
  let(:domain) { create(:pages_domain, project: project) }

  before do
    stub_lets_encrypt_settings
  end

  describe '#perform' do
    it 'delegates to ObtainLetsEncryptCertificateService' do
      service = double(:service)
      expect(::Pages::Domains::ObtainLetsEncryptCertificateService).to receive(:new).with(domain).and_return(service)
      expect(service).to receive(:execute)

      worker.perform(domain.id)
    end

    shared_examples 'does nothing' do
      it 'does nothing' do
        expect(::Pages::Domains::ObtainLetsEncryptCertificateService).not_to receive(:new)

        worker.perform(domain.id)
      end
    end

    context 'when domain was deleted' do
      before do
        domain.destroy!
      end

      include_examples 'does nothing'
    end

    context 'when domain is disabled' do
      let(:domain) { create(:pages_domain, :disabled) }

      include_examples 'does nothing'
    end
  end
end
