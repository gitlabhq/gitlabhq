# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/_broadcast_message.html.haml', feature_category: :notifications do
  describe 'render' do
    let(:dismissal_data) { "[data-dismissal-path=\"#{broadcast_message_dismissals_path}\"]" }

    before do
      allow(view).to receive(:current_user).and_return(current_user)
      allow(view).to receive(:message).and_return(build(:broadcast_message, dismissable: true))
    end

    describe 'when user is authenticated' do
      let(:current_user) { build(:user) }

      it 'adds dismissal path' do
        render 'shared/broadcast_message'

        expect(rendered).to have_css(dismissal_data)
      end
    end

    describe 'when user is not authenticated' do
      let(:current_user) { nil }

      it 'does not add dismissal path' do
        render 'shared/broadcast_message'

        expect(rendered).not_to have_css(dismissal_data)
      end
    end
  end
end
