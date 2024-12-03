# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::ResetPagesDefaultDomainRedirectWorker, feature_category: :pages do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:default_domain_url) { 'default.domain.com' }
  let_it_be(:non_default_domain_url) { 'non-default.domain.com' }
  let_it_be(:default_domain) { create(:pages_domain, project: project, domain: default_domain_url) }
  let_it_be(:non_default_domain) { create(:pages_domain, project: project, domain: non_default_domain_url) }
  let_it_be(:project_setting) do
    create(:project_setting, project: project, pages_default_domain_redirect: default_domain_url)
  end

  let(:event) do
    ::PagesDomains::PagesDomainDeletedEvent.new(data: {
      project_id: project.id,
      namespace_id: project.namespace_id,
      root_namespace_id: project.root_namespace.id,
      domain_id: default_domain.id,
      domain: default_domain_url
    })
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky
  it_behaves_like 'subscribes to event'

  subject(:use_event) { consume_event(subscriber: described_class, event: event) }

  context 'when the removed domain is the default domain' do
    it 'resets pages default domain redirect setting to nil' do
      default_domain.destroy!

      expect { use_event }
        .to change { project.reload.project_setting.pages_default_domain_redirect }
              .from(default_domain_url).to(nil)
    end
  end

  context 'when the removed domain is not the default domain' do
    let(:event) do
      ::PagesDomains::PagesDomainDeletedEvent.new(data: {
        project_id: project.id,
        namespace_id: project.namespace_id,
        root_namespace_id: project.root_namespace.id,
        domain_id: non_default_domain.id,
        domain: non_default_domain_url
      })
    end

    it 'does not change the pages default domain redirect setting' do
      non_default_domain.destroy!

      expect { use_event }
        .not_to change { project.reload.project_setting.pages_default_domain_redirect }
    end
  end
end
