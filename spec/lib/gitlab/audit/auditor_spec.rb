# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::Auditor, feature_category: :audit_events do
  let(:name) { 'audit_operation' }
  let(:author) { create(:user, :with_sign_ins) }
  let(:group) { create(:group) }
  let_it_be(:organization) { create(:organization) }
  let(:provider) { 'standard' }
  let(:context) do
    { name: name,
      author: author,
      scope: group,
      target: group,
      authentication_event: true,
      authentication_provider: provider,
      message: "Signed in using standard authentication",
      organization: organization }
  end

  let(:logger) { instance_spy(Gitlab::AuditJsonLogger) }

  subject(:auditor) { described_class }

  describe '.audit' do
    let(:audit!) { auditor.audit(context) }

    before do
      allow(Gitlab::Audit::Type::Definition).to receive(:defined?).and_call_original
      allow(Gitlab::Audit::Type::Definition).to receive(:defined?).with(name).and_return(true)
    end

    context 'when yaml definition is not defined' do
      before do
        allow(Gitlab::Audit::Type::Definition).to receive(:defined?).and_call_original
        allow(Gitlab::Audit::Type::Definition).to receive(:defined?).with(name).and_return(false)
      end

      it 'raises an error' do
        expected_error = "Audit event type YML file is not defined for audit_operation. " \
                         "Please read https://docs.gitlab.com/ee/development/audit_event_guide/" \
                         "#how-to-instrument-new-audit-events for adding a new audit event"

        expect { audit! }.to raise_error(StandardError, expected_error)
      end
    end

    context 'when yaml definition is defined' do
      before do
        allow(Gitlab::Audit::Type::Definition).to receive(:defined?).and_return(true)
        allow(Gitlab::AppLogger).to receive(:info).and_call_original
      end

      it 'does not raise an error' do
        expect { audit! }.not_to raise_error
      end
    end

    context 'when authentication event' do
      it 'creates an authentication event' do
        expect(AuthenticationEvent).to receive(:new).with(
          {
            user: author,
            user_name: author.name,
            ip_address: author.current_sign_in_ip,
            result: AuthenticationEvent.results[:success],
            provider: provider,
            organization: organization
          }
        ).and_call_original

        audit!

        authentication_event = AuthenticationEvent.last

        expect(authentication_event.user).to eq(author)
        expect(authentication_event.user_name).to eq(author.name)
        expect(authentication_event.ip_address).to eq(author.current_sign_in_ip)
        expect(authentication_event.provider).to eq(provider)
      end

      it 'does not write to the legacy AuditEvent table' do
        expect { audit! }.not_to change { AuditEvent.count }
      end

      it 'logs audit events to file' do
        expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

        audit!

        expect(logger).to have_received(:info).with(
          hash_including(
            'id' => AuditEvents::GroupAuditEvent.last.id,
            'author_id' => author.id,
            'author_name' => author.name,
            'entity_id' => group.id,
            'entity_type' => group.class.name,
            'details' => kind_of(Hash)
          )
        )
      end

      context 'when overriding the create datetime' do
        let(:context) do
          { name: name,
            author: author,
            scope: group,
            target: group,
            created_at: 3.weeks.ago,
            authentication_event: true,
            organization: organization,
            authentication_provider: provider,
            message: "Signed in using standard authentication" }
        end

        it 'logs audit events to file' do
          freeze_time do
            expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

            audit!

            expect(logger).to have_received(:info).with(
              hash_including(
                'id' => AuditEvents::GroupAuditEvent.last.id,
                'author_id' => author.id,
                'author_name' => author.name,
                'entity_id' => group.id,
                'entity_type' => group.class.name,
                'details' => kind_of(Hash),
                'created_at' => 3.weeks.ago.iso8601(3)
              )
            )
          end
        end
      end

      context 'when overriding the additional_details' do
        additional_details = { action: :custom, from: false, to: true }
        let(:context) do
          { name: name,
            author: author,
            scope: group,
            target: group,
            created_at: Time.zone.now,
            additional_details: additional_details,
            authentication_event: true,
            organization: organization,
            authentication_provider: provider,
            message: "Signed in using standard authentication" }
        end

        it 'logs audit events to file' do
          freeze_time do
            expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

            audit!

            expect(logger).to have_received(:info).with(
              hash_including(
                'details' => hash_including(
                  'action' => 'custom',
                  'from' => 'false',
                  'to' => 'true',
                  'event_name' => name
                ),
                'action' => 'custom',
                'from' => 'false',
                'to' => 'true'
              )
            )
          end
        end
      end

      context 'when overriding the target_details' do
        target_details = "this is my target details"
        let(:context) do
          {
            name: name,
            author: author,
            scope: group,
            target: group,
            created_at: Time.zone.now,
            target_details: target_details,
            authentication_event: true,
            organization: organization,
            authentication_provider: provider,
            message: "Signed in using standard authentication"
          }
        end

        it 'logs audit events to file' do
          freeze_time do
            expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

            audit!

            expect(logger).to have_received(:info).with(
              hash_including(
                'details' => hash_including('target_details' => target_details),
                'target_details' => target_details
              )
            )
          end
        end
      end
    end

    context 'when authentication event is false' do
      let(:target) { group }
      let(:context) do
        { name: name, author: author, scope: group,
          target: target, authentication_event: false, message: "sample message" }
      end

      it 'does not create an authentication event' do
        expect { auditor.audit(context) }.not_to change { AuthenticationEvent.count }
      end

      context 'with permitted target' do
        { feature_flag: :operations_feature_flag }.each do |target_type, factory_name|
          context "with #{target_type}" do
            let(:target) { build_stubbed factory_name }

            it 'does not write to the legacy AuditEvent table', :freeze_time do
              expect { audit! }.not_to change { AuditEvent.count }
            end
          end
        end
      end
    end

    context 'when authentication event is invalid' do
      before do
        allow(AuthenticationEvent).to receive(:new).and_raise(ActiveRecord::RecordInvalid)
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      it 'tracks error' do
        audit!

        expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
          kind_of(ActiveRecord::RecordInvalid),
          { audit_operation: name }
        )
      end

      it 'does not throw exception' do
        expect { auditor.audit(context) }.not_to raise_exception
      end
    end

    context 'when audit events are invalid' do
      before do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      let(:author) { build(:user) } # use non-persisted author (hence non-valid id)

      it 'tracks error' do
        audit!

        expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
          kind_of(ActiveRecord::RecordInvalid),
          { audit_operation: name }
        ).at_least(:once)
      end

      it 'does not throw exception' do
        expect { auditor.audit(context) }.not_to raise_exception
      end
    end
  end
end
