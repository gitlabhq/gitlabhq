# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::ResetPagesDefaultDomainRedirectWorker, feature_category: :pages do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:primary_domain_url) { 'primary.domain.com' }
  let_it_be(:non_primary_domain_url) { 'non-primary.domain.com' }
  let_it_be(:primary_domain) { create(:pages_domain, project: project, domain: primary_domain_url) }
  let_it_be(:non_primary_domain) { create(:pages_domain, project: project, domain: non_primary_domain_url) }
  let_it_be(:project_setting) do
    create(:project_setting, project: project, pages_primary_domain: primary_domain_url)
  end

  let(:event) do
    ::Pages::Domains::PagesDomainDeletedEvent.new(data: {
      project_id: project.id,
      namespace_id: project.namespace_id,
      root_namespace_id: project.root_namespace.id,
      domain_id: primary_domain.id,
      domain: primary_domain_url
    })
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky
  it_behaves_like 'subscribes to event'

  subject(:use_event) { consume_event(subscriber: described_class, event: event) }

  context 'when the removed domain is the primary domain' do
    it 'resets pages primary domain setting to nil' do
      primary_domain.destroy!

      expect { use_event }
        .to change { project.reload.project_setting.pages_primary_domain }
              .from(primary_domain_url).to(nil)
    end
  end

  context 'when the removed domain is not the primary domain' do
    let(:event) do
      ::Pages::Domains::PagesDomainDeletedEvent.new(data: {
        project_id: project.id,
        namespace_id: project.namespace_id,
        root_namespace_id: project.root_namespace.id,
        domain_id: non_primary_domain.id,
        domain: non_primary_domain_url
      })
    end

    it 'does not change the pages primary domain setting' do
      non_primary_domain.destroy!

      expect { use_event }
        .not_to change { project.reload.project_setting.pages_primary_domain }
    end
  end
end
