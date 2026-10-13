# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::UserEntity, feature_category: :user_management do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:admin) { build_stubbed(:user, :admin) }

  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- persisted records are required to exercise the real GID and organization membership query
  let_it_be(:organization_admin) { create(:user) }
  let_it_be(:organization) { create(:organization, owners: organization_admin) }
  let_it_be(:organization_user) { create(:user, organizations: [organization]) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:entity_subject) { user }
  let(:current_user) { admin }
  let(:authorization_context) { nil }

  let(:request) { double('request') }

  let(:entity) do
    described_class.new(
      entity_subject,
      request: request,
      current_user: current_user,
      authorization_context: authorization_context
    )
  end

  # This guardrail makes Admin::UserEntity fail-closed: every exposure must be a
  # deliberate choice. Organization admins reach this entity through the
  # organization admin area, so any new field is a potential instance-data leak.
  #
  # When you add an exposure, classify it in exactly one of the lists below:
  #   - safe_fields  - not instance-sensitive; may be shown to organization admins.
  #   - gated_fields - instance-sensitive; MUST carry an `if:` authorization
  #                    condition. The spec asserts the condition exists.
  #
  # The spec fails if an exposure is unclassified, or if a gated field has no
  # condition. Never move a field to safe_fields just to silence a failure.
  describe 'exposure authorization guardrail #security' do
    safe_fields = %i[
      id
      username
      public_email
      name
      created_at
      last_activity_on
      avatar_url
      badges
      actions
      organization_user_gid
    ]

    gated_fields = %i[email note]
    gated_fields += %i[oncall_schedules escalation_policies] if Gitlab.ee?

    classified_fields = safe_fields + gated_fields

    it 'classifies every exposure as safe or gated' do
      exposed = described_class.root_exposures.map(&:attribute)

      unclassified = exposed - classified_fields

      expect(unclassified).to be_empty, <<~MSG
        Admin::UserEntity exposes fields not classified in the guardrail: #{unclassified.inspect}.
        Add each to `safe_fields` (not instance-sensitive) or `gated_fields`
        (instance-sensitive, requires an `if:` authorization condition) in this spec.
      MSG
    end

    it 'requires every gated exposure to carry an authorization condition' do
      exposed = described_class.root_exposures.index_by(&:attribute)

      missing_conditions = gated_fields.select do |field|
        exposure = exposed[field]
        exposure.nil? || exposure.conditions.empty?
      end

      expect(missing_conditions).to be_empty, <<~MSG
        These instance-sensitive Admin::UserEntity fields must be exposed with an
        `if:` authorization condition but are not: #{missing_conditions.inspect}.
      MSG
    end
  end

  describe '#as_json' do
    subject { entity.as_json&.keys }

    context 'as an admin', :enable_admin_mode do
      it 'exposes correct attributes' do
        is_expected.to include(
          :id,
          :name,
          :created_at,
          :email,
          :username,
          :last_activity_on,
          :avatar_url,
          :note,
          :badges,
          :actions
        )
      end
    end

    context 'as an organization admin' do
      let(:entity_subject) { organization_user }
      let(:current_user) { organization_admin }
      let(:authorization_context) { organization }

      it 'does not expose note' do
        is_expected.not_to include(
          :note
        )
      end

      it 'does not expose email' do
        is_expected.not_to include(
          :email
        )
      end
    end

    context 'for organization_user_gid' do
      let(:gid) { 'gid://gitlab/Organizations::OrganizationUser/1' }

      it 'exposes the value returned by #organization_user_gid' do
        allow(entity).to receive(:organization_user_gid).with(user).and_return(gid)

        expect(entity.as_json[:organization_user_gid]).to eq(gid)
      end

      it 'exposes nil when there is no organization user' do
        allow(entity).to receive(:organization_user_gid).with(user).and_return(nil)

        expect(entity.as_json).to have_key(:organization_user_gid)
        expect(entity.as_json[:organization_user_gid]).to be_nil
      end

      context 'with a real organization user', :enable_admin_mode do
        let(:entity_subject) { organization_user }
        let(:current_user) { organization_admin }

        context 'when on the organization admin page' do
          let(:authorization_context) { organization }

          it 'exposes the organization user global ID' do
            expect(entity.as_json[:organization_user_gid]).to eq(
              organization.organization_users.by_user(organization_user).first.to_global_id.to_s
            )
          end
        end

        context 'when not on the organization admin page' do
          it 'exposes nil for the organization user global ID' do
            expect(entity.as_json[:organization_user_gid]).to be_nil
          end
        end
      end
    end
  end
end
