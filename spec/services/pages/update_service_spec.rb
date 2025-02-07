# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::UpdateService, feature_category: :pages do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project) }
  let(:domain) { 'my.domain.com' }
  let(:params) do
    {
      pages_unique_domain_enabled: false,
      pages_https_only: false,
      pages_primary_domain: domain
    }
  end

  before do
    stub_pages_setting(external_https: true)
    create(:pages_domain, project: project, domain: domain)
  end

  describe '#execute' do
    context 'with sufficient permissions' do
      let(:service) { described_class.new(project, user, params) }

      before do
        allow(service).to receive(:can?).with(user, :update_pages, project).and_return(true)
      end

      context 'when updating page setting succeeds' do
        it 'updates page settings' do
          create(:project_setting, project: project, pages_unique_domain_enabled: true,
            pages_unique_domain: "random-unique-domain-here")

          expect { service.execute }
            .to change { project.reload.pages_https_only }.from(true).to(false)
            .and change { project.project_setting.pages_unique_domain_enabled }.from(true).to(false)
            .and change { project.project_setting.pages_primary_domain }.from(nil).to(domain)
        end

        it 'returns a success response' do
          result = service.execute

          expect(result).to be_a(ServiceResponse)
          expect(result).to be_success
          expect(result.payload[:project]).to eq(project)
        end
      end
    end

    context 'with insufficient permissions' do
      let(:service) { described_class.new(project, user, params) }

      it 'returns a forbidden response' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq(_('The current user is not authorized to update the page settings'))
      end
    end
  end
end
