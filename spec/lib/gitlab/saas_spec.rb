# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Saas do
  describe '.canary_toggle_com_url' do
    subject { described_class.canary_toggle_com_url }

    let(:next_url) { 'https://next.gitlab.com' }

    it { is_expected.to eq(next_url) }
  end
end
