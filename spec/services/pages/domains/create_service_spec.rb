# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pages::Domains::CreateService, feature_category: :pages do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :in_subgroup) }

  let(:domain) { 'new.domain.com' }
  let(:attributes) { { domain: domain } }

  subject(:service) { described_class.new(project, user, attributes) }

  context 'when the user does not have the required permissions' do
    it 'does not create a pages domain and does not publish a PagesDomainCreatedEvent' do
      expect(service.execute).to be_nil

      expect { service.execute }
        .to not_publish_event(::Pages::Domains::PagesDomainCreatedEvent)
        .and not_change(project.pages_domains, :count)
    end
  end

  context 'when the user has the required permissions' do
    before_all do
      project.add_maintainer(user)
    end

    context 'when it saves the domain successfully' do
      it 'creates the domain and publishes a PagesDomainCreatedEvent' do
        pages_domain = nil

        expect { pages_domain = service.execute }
          .to change { project.pages_domains.count }
          .and publish_event(::Pages::Domains::PagesDomainCreatedEvent)
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
          .to not_publish_event(::Pages::Domains::PagesDomainCreatedEvent)
          .and not_change(project.pages_domains, :count)

        expect(pages_domain).not_to be_persisted
      end
    end

    context 'when domain already exists' do
      let_it_be(:existing_project) { create(:project) }
      let_it_be(:existing_domain) { create(:pages_domain, project: existing_project) }
      let(:params) { { domain: existing_domain.domain } }
      let(:service) { described_class.new(project, user, params) }

      subject(:result) { service.execute }

      it "returns generic error message" do
        expect(result).to be_a(PagesDomain)
        expect(result).not_to be_persisted
        expect(result.errors[:domain]).to include("is already in use by another project")
      end

      context "when the user is a developer on the conflicting project" do
        before do
          existing_project.add_member(user, :developer)
        end

        it "returns generic error message" do
          expect(result).to be_a(PagesDomain)
          expect(result).not_to be_persisted
          expect(result.errors[:domain]).to include("is already in use by another project")
        end
      end

      context "when the user is a maintainer on the conflicting project" do
        before do
          existing_project.add_member(user, :maintainer)
        end

        it "returns error message including the conflicting project path" do
          expect(result).to be_a(PagesDomain)
          expect(result).not_to be_persisted
          expect(result.errors[:domain])
            .to include("is already in use by project #{existing_domain.project.full_path}")
        end
      end
    end
  end
end
