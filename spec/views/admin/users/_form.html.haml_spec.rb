# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/users/_form.html.haml', feature_category: :user_management do
  let_it_be(:user) { build(:user, :guest) }

  before do
    assign(:user, user)
  end

  describe 'Access' do
    describe 'user top level group creation setting' do
      context 'when the user is not allowed to create a group' do
        before do
          allow(user).to receive(:allow_user_to_create_group_and_project?).and_return(false)
        end

        it 'hides the checkbox' do
          render

          expect(rendered).not_to have_field(
            'Can create top-level group',
            type: 'checkbox'
          )
        end
      end

      context 'when the user is allowed to create a group' do
        before do
          allow(user).to receive(:allow_user_to_create_group_and_project?).and_return(true)
        end

        it 'renders the checkbox' do
          render

          expect(rendered).to have_field(
            'Can create top-level group',
            type: 'checkbox'
          )
        end
      end
    end
  end
end
