# frozen_string_literal: true

require 'spec_helper'

describe 'projects/pages_domains/show' do
  let(:project) { create(:project, :repository) }

  before do
    assign(:project, project)
    assign(:domain, domain)
    stub_pages_setting(external_https: true)
  end

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
