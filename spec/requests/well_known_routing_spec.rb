# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'well-known URLs', feature_category: :system_access do
  describe '/.well-known/change-password' do
    it 'redirects to edit profile password path' do
      get('/.well-known/change-password')

      expect(response).to redirect_to(edit_profile_password_path)
    end
  end
end
