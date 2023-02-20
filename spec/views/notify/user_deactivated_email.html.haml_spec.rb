# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/user_deactivated_email.html.haml', feature_category: :user_management do
  let(:name) { 'John Smith' }

  before do
    assign(:name, name)
  end

  it "displays the user's name" do
    render

    expect(rendered).to have_content(/^Hello John Smith,/)
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

    context 'when additional text feature flag is disabled' do
      before do
        stub_feature_flags(deactivation_email_additional_text: false)
      end

      it 'does not display the additional text' do
        render

        expect(rendered).to have_content(/Please contact your GitLab administrator if you think this is an error\.$/)
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
