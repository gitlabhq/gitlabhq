# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ListUserPreference do
  let_it_be(:user) { create(:user) }
  let_it_be(:list) { create(:list) }

  before do
    list.update_preferences_for(user, { collapsed: true })
  end

  describe 'relationships' do
    it { is_expected.to belong_to(:list) }
    it { is_expected.to belong_to(:user) }

    it do
      is_expected.to validate_uniqueness_of(:user_id).scoped_to(:list_id)
                       .with_message("should have only one list preference per user")
    end
  end
end
