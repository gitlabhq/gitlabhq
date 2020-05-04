# frozen_string_literal: true

require 'spec_helper'

describe 'admin/users/_user.html.haml' do
  before do
    allow(view).to receive(:user).and_return(user)
  end

  context 'internal users' do
    context 'when showing a `Ghost User`' do
      let(:user) { create(:user, :ghost) }

      it 'does not render action buttons' do
        render

        expect(rendered).not_to have_selector('.table-action-buttons')
      end
    end

    context 'when showing a `Bot User`' do
      let(:user) { create(:user, user_type: :alert_bot) }

      it 'does not render action buttons' do
        render

        expect(rendered).not_to have_selector('.table-action-buttons')
      end
    end

    context 'when showing a `Migration User`' do
      let(:user) { create(:user, user_type: :migration_bot) }

      it 'does not render action buttons' do
        render

        expect(rendered).not_to have_selector('.table-action-buttons')
      end
    end
  end

  context 'when showing an external user' do
    let(:user) { create(:user) }

    it 'renders action buttons' do
      render

      expect(rendered).to have_selector('.table-action-buttons')
    end
  end
end
