# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pages::Domains::RetryAcmeOrderService, feature_category: :pages do
  let_it_be(:project) { create(:project) }

  let(:domain) { create(:pages_domain, project: project, auto_ssl_enabled: true, auto_ssl_failed: true) }

  let(:service) { described_class.new(domain) }

  it 'clears auto_ssl_failed' do
    expect { service.execute }
      .to change { domain.auto_ssl_failed }
      .from(true).to(false)
      .and publish_event(::Pages::Domains::PagesDomainUpdatedEvent)
      .with(
        project_id: project.id,
        namespace_id: project.namespace.id,
        root_namespace_id: project.root_namespace.id,
        domain_id: domain.id,
        domain: domain.domain
      )
  end

  it 'schedules renewal worker and publish PagesDomainUpdatedEvent event' do
    expect(PagesDomainSslRenewalWorker).to receive(:perform_async).with(domain.id).and_return(nil).once

    expect { service.execute }
      .to publish_event(::Pages::Domains::PagesDomainUpdatedEvent)
      .with(
        project_id: project.id,
        namespace_id: project.namespace.id,
        root_namespace_id: project.root_namespace.id,
        domain_id: domain.id,
        domain: domain.domain
      )
  end

  it "doesn't schedule renewal worker if Let's Encrypt integration is not enabled" do
    domain.update!(auto_ssl_enabled: false)

    expect(PagesDomainSslRenewalWorker).not_to receive(:new)

    expect { service.execute }
      .to not_publish_event(::Pages::Domains::PagesDomainUpdatedEvent)
  end

  it "doesn't schedule renewal worker if auto ssl has not failed yet" do
    domain.update!(auto_ssl_failed: false)

    expect(PagesDomainSslRenewalWorker).not_to receive(:new)

    expect { service.execute }
      .to not_publish_event(::Pages::Domains::PagesDomainUpdatedEvent)
  end
end
