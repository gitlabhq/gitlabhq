require 'spec_helper'

describe 'projects/pages_domains/show' do
  let(:project) { create(:project, :repository) }

  before do
    assign(:project, project)
    assign(:domain, domain)
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

    context 'when certificate is present' do
      let(:domain) { create(:pages_domain, :letsencrypt, project: project) }

      it 'shows certificate info' do
        render

        # test just a random part of cert represenations(X509v3 Subject Key Identifier:)
        expect(rendered).to have_content("C6:5F:56:4B:10:69:AC:1D:33:D2:26:C9:B3:7A:D7:12:4D:3E:F7:90")
      end
    end
  end

  context 'when auto_ssl is disabled' do
    context 'when certificate is present' do
      let(:domain) { create(:pages_domain, project: project) }

      it 'shows certificate info' do
        render

        # test just a random part of cert represenations(X509v3 Subject Key Identifier:)
        expect(rendered).to have_content("C6:5F:56:4B:10:69:AC:1D:33:D2:26:C9:B3:7A:D7:12:4D:3E:F7:90")
      end
    end

    context 'when certificate is absent' do
      let(:domain) { create(:pages_domain, :without_certificate, :without_key, project: project) }

      it 'shows missing certificate' do
        render

        expect(rendered).to have_content("missing")
      end
    end
  end
end
