# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SentNotificationsController, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }

  describe 'GET #unsubscribe' do
    let_it_be_with_reload(:sent_notification) { create(:sent_notification, project: project) }

    # The namespace-scoped route is the CELLS-routable route and carries the bulk of the coverage.
    context 'when the route is namespace-scoped' do
      let(:unsubscribe_path) do
        unsubscribe_namespace_sent_notification_path(sent_notification.namespace_id, sent_notification)
      end

      context 'when user is not authenticated' do
        it 'renders a confirmation form to unsubscribe' do
          get unsubscribe_path

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to have_link(
            'Unsubscribe',
            href: unsubscribe_namespace_sent_notification_path(
              sent_notification.namespace_id, sent_notification, force: true
            )
          )
        end
      end

      context 'when sent_notification is not found' do
        it 'renders an expired link view' do
          path = unsubscribe_path

          SentNotification.where(id: sent_notification.id).delete_all

          get path

          expect(response.body).to include(_('This link is no longer valid.'))
        end
      end

      context 'when the namespace_id does not match the sent_notification' do
        it 'renders an expired link view' do
          get unsubscribe_namespace_sent_notification_path(non_existing_record_id, sent_notification)

          expect(response.body).to include(_('This link is no longer valid.'))
        end
      end
    end

    # The legacy route shares the same controller, so a single smoke test is enough.
    # The confirmation form always points to the namespace-scoped route.
    context 'when the route is the legacy unscoped route' do
      it 'renders a confirmation form linking to the namespace-scoped unsubscribe path' do
        get unsubscribe_sent_notification_path(sent_notification)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to have_link(
          'Unsubscribe',
          href: unsubscribe_namespace_sent_notification_path(
            sent_notification.namespace_id, sent_notification, force: true
          )
        )
      end
    end
  end
end
