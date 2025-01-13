# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/user_deactivated_email.html.haml', feature_category: :user_management do
  let(:name) { 'John Smith' }
  let(:host) { 'gitlab.example.com' }

  before do
    assign(:name, name)
    assign(:host, host)
  end

  it "displays the user's name" do
    render

    expect(rendered).to have_content(/^Hello John Smith,/)
  end

  it 'includes the GitLab host' do
    render

    expect(rendered).to have_content(/Your account has been deactivated for #{host}\./)
  end

  context 'when additional text setting is set' do
    before do
      allow(Gitlab::CurrentSettings).to receive(:deactivation_email_additional_text)
        .and_return('So long and thanks for all the fish!')
    end

    context 'when additional text feature flag is enabled' do
      it 'displays the additional text' do
        render

        expect(rendered).to have_content(/So long and thanks for all the fish!$/)
      end
    end
  end

  context 'when additional text setting is not set' do
    before do
      allow(Gitlab::CurrentSettings).to receive(:deactivation_email_additional_text).and_return('')
    end

    it 'does not display any additional text' do
      render

      expect(rendered).to have_content(/Please contact your GitLab administrator if you think this is an error\.$/)
    end
  end
end
