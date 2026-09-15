# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::UserEntity do
  let_it_be(:user) { build_stubbed(:user) }

  let(:request) { double('request') }

  let(:entity) do
    described_class.new(user, request: request)
  end

  describe '#as_json' do
    subject { entity.as_json&.keys }

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

      # rubocop:disable RSpec/FactoryBot/AvoidCreate -- persisted records are required to exercise the real GID and organization membership query
      context 'with a real organization user', :enable_admin_mode do
        let_it_be(:organization) { create(:organization) }
        let_it_be(:user) { create(:user, organizations: [organization]) }
        let_it_be(:current_user) { create(:organization_owner, organization: organization).user }

        context 'when on the organization admin page' do
          let(:entity) do
            described_class.new(
              user, request: request, current_user: current_user, authorization_context: organization
            )
          end

          it 'exposes the organization user global ID' do
            organization_user = organization.organization_users.by_user(user).first

            expect(entity.as_json[:organization_user_gid]).to eq(organization_user.to_global_id.to_s)
          end
        end

        context 'when not on the organization admin page' do
          let(:entity) do
            described_class.new(
              user, request: request, current_user: current_user, authorization_context: nil
            )
          end

          it 'exposes nil for the organization user global ID' do
            expect(entity.as_json[:organization_user_gid]).to be_nil
          end
        end
      end
      # rubocop:enable RSpec/FactoryBot/AvoidCreate
    end
  end
end
