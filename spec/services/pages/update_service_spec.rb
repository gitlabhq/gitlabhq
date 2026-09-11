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
    stub_pages_setting(enabled: true, external_https: true)
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

      context 'when enabling the unique domain for a project without one' do
        let(:params) { { pages_unique_domain_enabled: true } }

        before do
          create(:project_setting, project: project, pages_unique_domain_enabled: false)
        end

        it 'generates a unique domain and enables it' do
          expect(service.execute).to be_success

          project_setting = project.project_setting.reload
          expect(project_setting.pages_unique_domain_enabled).to be(true)
          expect(project_setting.pages_unique_domain).to be_present
        end

        context 'when no unique domain can be generated' do
          before do
            create(:project_setting, pages_unique_domain: 'existing-domain')
            allow(Gitlab::Pages::RandomDomain).to receive(:generate).and_return('existing-domain')
          end

          it 'returns an unprocessable entity response and leaves the unique domain disabled' do
            result = service.execute

            expect(result).to be_error
            expect(result.reason).to eq(:unprocessable_entity)
            expect(result.message).to eq("Can't generate unique domain for GitLab Pages")
            expect(project.project_setting.reload.pages_unique_domain_enabled).to be(false)
          end
        end
      end

      context 'when the update is invalid' do
        let(:params) { { pages_https_only: true } }

        before do
          project.update!(pages_https_only: false)
          create(:pages_domain, :without_certificate, :without_key, project: project)
        end

        it 'returns an unprocessable entity response' do
          result = service.execute

          expect(result).to be_error
          expect(result.reason).to eq(:unprocessable_entity)
          expect(result.message).to eq('Pages https only cannot be enabled unless all domains have TLS certificates')
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
