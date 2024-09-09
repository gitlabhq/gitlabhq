# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::GroupMemberBuilder do
  let_it_be(:group) { create(:group) }
  let_it_be(:group_member) { create(:group_member, :developer, group: group, expires_at: 1.day.from_now) }

  describe '#build' do
    let(:data) { described_class.new(group_member).build(event) }
    let(:event_name) { data[:event_name] }
    let(:attributes) do
      [
        :event_name, :created_at, :updated_at, :expires_at, :group_name, :group_path,
        :group_id, :user_id, :user_username, :user_name, :user_email, :group_access
      ]
    end

    context 'data' do
      shared_examples_for 'includes the required attributes' do
        it 'includes the required attributes' do
          expect(data).to include(*attributes)

          expect(data[:group_name]).to eq(group.name)
          expect(data[:group_path]).to eq(group.path)
          expect(data[:group_id]).to eq(group.id)
          expect(data[:user_username]).to eq(group_member.user.username)
          expect(data[:user_name]).to eq(group_member.user.name)
          expect(data[:user_email]).to eq(group_member.user.webhook_email)
          expect(data[:user_id]).to eq(group_member.user.id)
          expect(data[:group_access]).to eq('Developer')
          expect(data[:created_at]).to eq(group_member.created_at&.xmlschema)
          expect(data[:updated_at]).to eq(group_member.updated_at&.xmlschema)
          expect(data[:expires_at]).to eq(group_member.expires_at&.xmlschema)
        end
      end

      context 'on create' do
        let(:event) { :create }

        it { expect(event_name).to eq('user_add_to_group') }

        it_behaves_like 'includes the required attributes'
      end

      context 'on update' do
        let(:event) { :update }

        it { expect(event_name).to eq('user_update_for_group') }

        it_behaves_like 'includes the required attributes'
      end

      context 'on destroy' do
        let(:event) { :destroy }

        it { expect(event_name).to eq('user_remove_from_group') }

        it_behaves_like 'includes the required attributes'
      end

      context 'on request' do
        let(:event) { :request }

        it { expect(event_name).to eq('user_access_request_to_group') }

        it_behaves_like 'includes the required attributes'
      end

      context 'on deny' do
        let(:event) { :revoke }

        it { expect(event_name).to eq('user_access_request_revoked_for_group') }

        it_behaves_like 'includes the required attributes'
      end
    end
  end
end
