# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/pages/show' do
  include LetsEncryptHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:domain) { create(:pages_domain, project: project) }

  before do
    allow(project).to receive(:pages_deployed?).and_return(true)
    stub_pages_setting(external_https: true)
    stub_lets_encrypt_settings
    project.add_maintainer(user)

    assign(:project, project)
    allow(view).to receive(:current_user).and_return(user)
    assign(:domains, [domain.present(current_user: user)])
  end

  describe 'validation warning' do
    let(:warning_message) do
      "#{domain.domain} is not verified. To learn how to verify ownership, "\
      "visit your domain details."
    end

    it "doesn't show auto ssl error warning" do
      render

      expect(rendered).not_to have_content(warning_message)
    end

    context "when domain is not verified" do
      before do
        domain.update!(verified_at: nil)
      end

      it 'shows auto ssl error warning' do
        render

        expect(rendered).to have_content(warning_message)
      end
    end
  end

  describe "warning about failed Let's Encrypt" do
    let(:error_message) do
      "Something went wrong while obtaining the Let's Encrypt certificate for #{domain.domain}. "\
      "To retry visit your domain details."
    end

    it "doesn't show auto ssl error warning" do
      render

      expect(rendered).not_to have_content(error_message)
    end

    context "when we failed to obtain Let's Encrypt's certificate" do
      before do
        domain.update!(auto_ssl_failed: true)
      end

      it 'shows auto ssl error warning' do
        render

        expect(rendered).to have_content(error_message)
      end
    end
  end
end
