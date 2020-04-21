# frozen_string_literal: true

require 'spec_helper'

describe 'profiles/show' do
  let(:user) { create(:user) }

  before do
    assign(:user, user)
    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive(:experiment_enabled?)
  end

  context 'when the profile page is opened' do
    it 'displays the correct elements' do
      render

      expect(rendered).to have_field('user_name', with: user.name)
      expect(rendered).to have_field('user_id', with: user.id)
    end
  end
end
