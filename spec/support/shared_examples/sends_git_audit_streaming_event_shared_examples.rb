# frozen_string_literal: true

RSpec.shared_examples 'sends git audit streaming event' do
  let_it_be(:user) { create(:user) }

  before do
    stub_licensed_features(external_audit_events: true)
  end

  subject {}

  context 'for public groups and projects' do
    let(:group) { create(:group, :public) }
    let(:project) { create(:project, :public, :repository, namespace: group) }

    before do
      group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
      project.add_developer(user)
    end

    context 'when user not logged in' do
      let(:key) { create(:key) }

      before do
        if request
          request.headers.merge! auth_env(user.username, nil, nil)
        end
      end
      it 'sends the audit streaming event' do
        expect(AuditEvents::AuditEventStreamingWorker).not_to receive(:perform_async)
        subject
      end
    end
  end

  context 'for private groups and projects' do
    let(:group) { create(:group, :private) }
    let(:project) { create(:project, :private, :repository, namespace: group) }

    before do
      group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
      project.add_developer(user)
      sign_in(user)
    end

    context 'when user logged in' do
      let(:key) { create(:key, user: user) }

      before do
        if request
          password = user.try(:password) || user.try(:token)
          request.headers.merge! auth_env(user.username, password, nil)
        end
      end
      it 'sends the audit streaming event' do
        expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).once
        subject
      end
    end
  end
end
