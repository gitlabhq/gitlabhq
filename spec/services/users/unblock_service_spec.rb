# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UnblockService, feature_category: :user_management do
  let_it_be(:current_user) { create(:admin) }

  subject(:service) { described_class.new(current_user) }

  describe '#execute' do
    subject(:operation) { service.execute(user) }

    context 'when successful' do
      let(:user) { create(:user, :blocked) }

      it { expect(operation.success?).to eq(true) }

      it "change the user's state" do
        expect { operation }.to change { user.active? }.to(true)
      end

      it 'saves a custom attribute', :aggregate_failures, :freeze_time, feature_category: :insider_threat do
        operation

        custom_attribute = user.custom_attributes.last

        expect(custom_attribute.key).to eq(UserCustomAttribute::UNBLOCKED_BY)
        expect(custom_attribute.value).to eq("#{current_user.username}/#{current_user.id}+#{Time.current}")
      end
    end

    context 'when failed' do
      let(:user) { create(:user) }

      it 'returns error result', :aggregate_failures do
        expect(operation.error?).to eq(true)
        expect(operation[:message]).to include(/State cannot transition/)
      end

      it "does not change the user's state" do
        expect { operation }.not_to change { user.state }
      end
    end
  end
end
