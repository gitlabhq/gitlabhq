# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/registrations/new', feature_category: :user_management do
  describe 'broadcast messaging' do
    before do
      allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
      allow(view).to receive(:resource).and_return(build(:user))
      allow(view).to receive(:resource_name).and_return(:user)
      allow(view).to receive(:registration_path_params).and_return({})
      allow(view).to receive(:glm_tracking_params).and_return({})
      allow(view).to receive(:arkose_labs_enabled?).and_return(true)
    end

    it 'does not render the broadcast layout' do
      render

      expect(rendered).not_to render_template('layouts/_broadcast')
    end

    context 'when SaaS', :saas do
      it 'does not render the broadcast layout' do
        render

        expect(rendered).not_to render_template('layouts/_broadcast')
      end
    end
  end
end
