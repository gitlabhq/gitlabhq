# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ClickHouse, feature_category: :database do
  subject { described_class }

  context 'when ClickHouse is not configured' do
    it { is_expected.not_to be_configured }
  end

  context 'when ClickHouse is configured', :click_house do
    it { is_expected.to be_configured }
  end
end
