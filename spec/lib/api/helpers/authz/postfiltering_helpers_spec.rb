# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::Authz::PostfilteringHelpers, feature_category: :permissions do
  let(:helper) { Class.new.include(described_class).new }

  let(:collection) { [1, 2, 3, 4, 5, 6] }
  let(:filter_proc) { -> { collection.select(&:even?) } }
  let_it_be(:current_user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(current_user)
  end

  describe '#filter_with_logging' do
    subject(:filter_with_logging) do
      helper.filter_with_logging(collection: collection, filter_proc: filter_proc, resource_type: 'api/evens')
    end

    before do
      stub_feature_flags(postfilter_logging: true)
    end

    it 'logs and calls the proc' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        message: "Post-filtering - api/evens",
        redacted_count: 3,
        collection_count: 6,
        postfiltering_duration: an_instance_of(Float),
        user_id: current_user.id
      ).and_call_original

      expect(filter_with_logging).to match_array([2, 4, 6])
    end

    context 'when exception is raised during logging' do
      it 'logs an error and bubbles the exception' do
        allow(Gitlab::AppLogger).to receive(:info).and_raise(StandardError.new('oopsy!'))

        expect(Gitlab::AppLogger).to receive(:warn).with(
          message: "Post-filtering failed - api/evens",
          error_class: 'StandardError',
          error_message: 'oopsy!',
          user_id: current_user.id
        ).and_call_original

        expect { filter_with_logging }.to raise_error(StandardError, 'oopsy!')
      end
    end

    context 'when current_user is nil' do
      let(:current_user) { nil }

      it 'calls the proc without logging' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        expect(filter_with_logging).to match_array([2, 4, 6])
      end
    end

    context 'when postfilter_logging feature is disabled' do
      before do
        stub_feature_flags(postfilter_logging: false)
      end

      it 'calls the proc without logging' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        expect(filter_with_logging).to match_array([2, 4, 6])
      end
    end
  end
end
