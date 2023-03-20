# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::BlockService, feature_category: :user_management do
  let_it_be(:current_user) { create(:admin) }

  subject(:service) { described_class.new(current_user) }

  describe '#execute' do
    subject(:operation) { service.execute(user) }

    context 'when successful' do
      let(:user) { create(:user) }

      it { is_expected.to eq(status: :success) }

      it "change the user's state" do
        expect { operation }.to change { user.state }.to('blocked')
      end

      it 'saves a custom attribute', :aggregate_failures, :freeze_time, feature_category: :insider_threat do
        operation

        custom_attribute = user.custom_attributes.last

        expect(custom_attribute.key).to eq(UserCustomAttribute::BLOCKED_BY)
        expect(custom_attribute.value).to eq("#{current_user.username}/#{current_user.id}+#{Time.current}")
      end
    end

    context 'when failed' do
      let(:user) { create(:user, :blocked) }

      it 'returns error result' do
        aggregate_failures 'error result' do
          expect(operation[:status]).to eq(:error)
          expect(operation[:message]).to match(/State cannot transition/)
        end
      end

      it "does not change the user's state" do
        expect { operation }.not_to change { user.state }
      end
    end

    context 'when internal user' do
      let(:user) { create(:user, :bot) }

      it 'returns error result' do
        expect(operation[:status]).to eq(:error)
        expect(operation[:message]).to eq('An internal user cannot be blocked')
        expect(operation[:http_status]).to eq(403)
      end
    end
  end
end
