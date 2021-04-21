# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDomainSslRenewalCronWorker do
  include LetsEncryptHelpers

  subject(:worker) { described_class.new }

  before do
    stub_lets_encrypt_settings
  end

  describe '#perform' do
    let_it_be(:project) { create :project }

    let!(:domain) { create(:pages_domain, project: project, auto_ssl_enabled: false) }
    let!(:domain_with_enabled_auto_ssl) { create(:pages_domain, project: project, auto_ssl_enabled: true) }
    let!(:domain_with_obtained_letsencrypt) do
      create(:pages_domain, :letsencrypt, project: project, auto_ssl_enabled: true)
    end

    let!(:domain_without_auto_certificate) do
      create(:pages_domain, :without_certificate, :without_key, project: project, auto_ssl_enabled: true)
    end

    let!(:domain_with_failed_auto_ssl) do
      create(:pages_domain, :without_certificate, :without_key, project: project,
             auto_ssl_enabled: true, auto_ssl_failed: true)
    end

    let!(:domain_with_expired_auto_ssl) do
      create(:pages_domain, :letsencrypt, :with_expired_certificate, project: project)
    end

    it 'enqueues a PagesDomainSslRenewalWorker for domains needing renewal' do
      [domain_without_auto_certificate,
       domain_with_enabled_auto_ssl,
       domain_with_expired_auto_ssl].each do |domain|
        expect(PagesDomainSslRenewalWorker).to receive(:perform_async).with(domain.id)
      end

      [domain,
       domain_with_obtained_letsencrypt,
       domain_with_failed_auto_ssl].each do |domain|
        expect(PagesDomainSslRenewalWorker).not_to receive(:perform_async).with(domain.id)
      end

      worker.perform
    end

    it_behaves_like 'a pages cronjob scheduling jobs with context', PagesDomainSslRenewalWorker do
      let(:extra_domain) { create(:pages_domain, :with_project, auto_ssl_enabled: true) }
    end

    shared_examples 'does nothing' do
      it 'does nothing' do
        expect(PagesDomainSslRenewalWorker).not_to receive(:perform_async)

        worker.perform
      end
    end

    context 'when letsencrypt integration is disabled' do
      before do
        stub_application_setting(
          lets_encrypt_terms_of_service_accepted: false
        )
      end

      include_examples 'does nothing'
    end
  end
end
