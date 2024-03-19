# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::IpBlocked, feature_category: :system_access do
  subject(:err) { described_class.new }

  it { is_expected.to be_a(StandardError) }

  describe '#message' do
    subject(:message) { err.message }

    it { is_expected.to eq(_('Too many failed authentication attempts from this IP')) }
  end
end
