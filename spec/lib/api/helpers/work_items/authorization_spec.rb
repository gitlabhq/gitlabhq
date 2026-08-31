# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::WorkItems::Authorization, feature_category: :portfolio_management do
  # `freeze: false` is required in this spec: the bare helper instance is a non-AR subject that
  # cannot be deep-frozen. Do not convert it to `let_it_be_with_reload`/`refind`.
  let_it_be(:helper, freeze: false) do
    Class.new.include(API::Helpers).include(described_class).new
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:work_item) { create(:work_item) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#check_work_item_rest_api_feature_flag!' do
    subject(:check) { helper.check_work_item_rest_api_feature_flag! }

    context 'when the feature flag is enabled for the user' do
      it 'permits the request' do
        expect(helper).not_to receive(:forbidden!)

        check
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(work_item_rest_api: false)
      end

      it 'forbids the request' do
        expect(helper).to receive(:forbidden!)
          .with('work_item_rest_api feature flag is disabled for this user')

        check
      end
    end
  end

  describe '#authorize_work_item_feature!' do
    subject(:authorize) { helper.authorize_work_item_feature!(work_item) }

    it 'gates on the feature flag before authorizing the work item' do
      expect(helper).to receive(:check_work_item_rest_api_feature_flag!).ordered
      expect(helper).to receive(:authorize!).with(:read_work_item, work_item).ordered

      authorize
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(work_item_rest_api: false)
      end

      it 'forbids the request' do
        expect(helper).to receive(:forbidden!)
          .with('work_item_rest_api feature flag is disabled for this user')
        allow(helper).to receive(:authorize!)

        authorize
      end
    end
  end
end
