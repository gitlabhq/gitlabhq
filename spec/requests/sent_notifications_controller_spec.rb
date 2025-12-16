# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SentNotificationsController, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }

  describe 'GET #unsubscribe' do
    let_it_be_with_reload(:sent_notification) { create(:sent_notification, project: project) }

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

    context 'when sent_notification is not found' do
      it 'renders an expired link view' do
        unsubscribe_url = unsubscribe_sent_notification_path(sent_notification)

        SentNotification.where(id: sent_notification.id).delete_all

        get unsubscribe_url

        expect(response.body).to include(_('This link is no longer valid.'))
      end
    end
  end
end
