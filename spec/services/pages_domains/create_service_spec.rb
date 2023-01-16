# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::PagesDomains::CreateService, feature_category: :pages do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :in_subgroup) }

  let(:domain) { 'new.domain.com' }
  let(:attributes) { { domain: domain } }

  subject(:service) { described_class.new(project, user, attributes) }

  context 'when the user does not have the required permissions' do
    it 'does not create a pages domain and does not publish a PagesDomainCreatedEvent' do
      expect(service.execute).to be_nil

      expect { service.execute }
        .to not_publish_event(PagesDomains::PagesDomainCreatedEvent)
        .and not_change(project.pages_domains, :count)
    end
  end

  context 'when the user has the required permissions' do
    before do
      project.add_maintainer(user)
    end

    context 'when it saves the domain successfully' do
      it 'creates the domain and publishes a PagesDomainCreatedEvent' do
        pages_domain = nil

        expect { pages_domain = service.execute }
          .to change(project.pages_domains, :count)
          .and publish_event(PagesDomains::PagesDomainCreatedEvent)
          .with(
            project_id: project.id,
            namespace_id: project.namespace.id,
            root_namespace_id: project.root_namespace.id,
            domain_id: kind_of(Numeric),
            domain: domain
          )

        expect(pages_domain).to be_persisted
      end
    end

    context 'when it fails to save the domain' do
      let(:domain) { nil }

      it 'does not create a pages domain and does not publish a PagesDomainCreatedEvent' do
        pages_domain = nil

        expect { pages_domain = service.execute }
          .to not_publish_event(PagesDomains::PagesDomainCreatedEvent)
          .and not_change(project.pages_domains, :count)

        expect(pages_domain).not_to be_persisted
      end
    end
  end
end
