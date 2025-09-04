# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SentNotificationsController, feature_category: :team_planning do
  include SentNotificationHelpers

  let_it_be(:project) { create(:project) }

  describe 'GET #unsubscribe' do
    let_it_be(:sent_notification) { create_sent_notification(project: project) }

    context 'when user is not authenticated' do
      it 'renders a confirmation form to unsubscribe' do
        get unsubscribe_sent_notification_path(sent_notification)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to have_link(
          'Unsubscribe',
          href: unsubscribe_sent_notification_path(sent_notification, force: true)
        )
      end
    end
  end
end
