# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Saas do
  include SaasTestHelper

  describe '.canary_toggle_com_url' do
    subject { described_class.canary_toggle_com_url }

    it { is_expected.to eq(get_next_url) }
  end
end
