# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DismissUserCalloutService do
  let(:user) { create(:user) }

  let(:service) do
    described_class.new(
      container: nil, current_user: user, params: { feature_name: UserCallout.feature_names.each_key.first }
    )
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    it 'returns a user callout' do
      expect(execute).to be_an_instance_of(UserCallout)
    end

    it 'sets the dismisse_at attribute to current time' do
      freeze_time do
        expect(execute).to have_attributes(dismissed_at: Time.current)
      end
    end
  end
end
