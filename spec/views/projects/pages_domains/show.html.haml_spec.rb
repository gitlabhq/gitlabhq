# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/pages_domains/show' do
  let(:project) { create(:project, :repository) }

  shared_examples 'pages domain tests' do
    context 'when auto_ssl is enabled' do
      context 'when domain is disabled' do
        let(:domain) { create(:pages_domain, :disabled, project: project, auto_ssl_enabled: true) }

        it 'shows verification warning' do
          render

          expect(rendered).to have_content("A Let's Encrypt SSL certificate can not be obtained until your domain is verified.")
        end
      end

      context 'when certificate is absent' do
        let(:domain) { create(:pages_domain, :without_key, :without_certificate, project: project, auto_ssl_enabled: true) }

        it 'shows alert about time of obtaining certificate' do
          render

          expect(rendered).to have_content("GitLab is obtaining a Let's Encrypt SSL certificate for this domain. This process can take some time. Please try again later.")
        end
      end
    end
  end

  context 'when external_https is true' do
    before do
      assign(:project, project)
      allow(view).to receive(:domain_presenter).and_return(domain.present)
      stub_pages_setting(external_https: true, custom_domain_mode: 'https')
    end

    include_examples 'pages domain tests'
  end

  context 'when external_https is false' do
    before do
      assign(:project, project)
      allow(view).to receive(:domain_presenter).and_return(domain.present)
      stub_pages_setting(external_https: false, custom_domain_mode: 'https')
    end

    include_examples 'pages domain tests'
  end
end
