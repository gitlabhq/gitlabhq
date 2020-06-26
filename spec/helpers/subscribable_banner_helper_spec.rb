# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubscribableBannerHelper do
  describe '#display_subscription_banner!' do
    it 'is over-written in EE' do
      expect { helper.display_subscription_banner! }.not_to raise_error
    end
  end
end
