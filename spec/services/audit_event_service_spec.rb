# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEventService, :with_license, feature_category: :audit_events do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, :with_sign_ins) }
  let_it_be(:project_member) { create(:project_member, user: user) }

  let(:service) { described_class.new(user, project, { action: :destroy }) }
  let(:logger) { instance_double(Gitlab::AuditJsonLogger) }

  describe '#security_event' do
    it 'creates an event and logs to a file' do
      expect(service).to receive(:file_logger).and_return(logger)
      expect(logger).to receive(:info).with({ author_id: user.id,
                                              author_name: user.name,
                                              entity_id: project.id,
                                              entity_type: "Project",
                                              action: :destroy,
                                              created_at: anything })

      expect { service.security_event }.to change(AuditEvent, :count).by(1)
    end

    it 'formats from and to fields' do
      service = described_class.new(
        user, project,
        {
          from: true,
          to: false,
          action: :create,
          target_id: 1
        })
      expect(service).to receive(:file_logger).and_return(logger)
      expect(logger).to receive(:info).with({ author_id: user.id,
                                              author_name: user.name,
                                              entity_type: 'Project',
                                              entity_id: project.id,
                                              from: 'true',
                                              to: 'false',
                                              action: :create,
                                              target_id: 1,
                                              created_at: anything })

      expect { service.security_event }.to change(AuditEvent, :count).by(1)

      details = AuditEvent.last.details
      expect(details[:from]).to be true
      expect(details[:to]).to be false
      expect(details[:action]).to eq(:create)
      expect(details[:target_id]).to eq(1)
    end

    context 'when defining created_at manually' do
      let(:service) { described_class.new(user, project, { action: :destroy }, :database, 3.weeks.ago) }

      it 'is overridden successfully' do
        freeze_time do
          expect(service).to receive(:file_logger).and_return(logger)
          expect(logger).to receive(:info).with({ author_id: user.id,
                                                  author_name: user.name,
                                                  entity_id: project.id,
                                                  entity_type: "Project",
                                                  action: :destroy,
                                                  created_at: 3.weeks.ago })

          expect { service.security_event }.to change(AuditEvent, :count).by(1)
          expect(AuditEvent.last.created_at).to eq(3.weeks.ago)
        end
      end
    end

    context 'authentication event' do
      let(:audit_service) { described_class.new(user, user, with: 'standard') }

      it 'creates an authentication event' do
        expect(AuthenticationEvent).to receive(:new).with(
          {
            user: user,
            user_name: user.name,
            ip_address: user.current_sign_in_ip,
            result: AuthenticationEvent.results[:success],
            provider: 'standard'
          }
        ).and_call_original

        audit_service.for_authentication.security_event
      end

      it 'tracks exceptions when the event cannot be created' do
        allow_next_instance_of(AuditEvent) do |event|
          allow(event).to receive(:valid?).and_return(false)
        end

        expect(Gitlab::ErrorTracking).to(
          receive(:track_and_raise_for_dev_exception)
        )

        audit_service.for_authentication.security_event
      end

      context 'with IP address', :request_store do
        using RSpec::Parameterized::TableSyntax

        where(:from_context, :from_author_sign_in, :output) do
          '192.168.0.2' | '192.168.0.3' | '192.168.0.2'
          nil           | '192.168.0.3' | '192.168.0.3'
        end

        with_them do
          let(:user) { create(:user, current_sign_in_ip: from_author_sign_in) }
          let(:audit_service) { described_class.new(user, user, with: 'standard') }

          before do
            allow(Gitlab::RequestContext.instance).to receive(:client_ip).and_return(from_context)
          end

          specify do
            expect(AuthenticationEvent).to receive(:new).with(hash_including(ip_address: output)).and_call_original

            audit_service.for_authentication.security_event
          end
        end
      end
    end
  end

  describe '#log_security_event_to_file' do
    it 'logs security event to file' do
      expect(service).to receive(:file_logger).and_return(logger)
      expect(logger).to receive(:info).with({ author_id: user.id,
                                              author_name: user.name,
                                              entity_type: 'Project',
                                              entity_id: project.id,
                                              action: :destroy,
                                              created_at: anything })

      service.log_security_event_to_file
    end
  end
end
