# frozen_string_literal: true

require 'fast_spec_helper'
require 'device_detector'
require_relative '../../../lib/gitlab/safe_device_detector'

RSpec.describe Gitlab::SafeDeviceDetector, feature_category: :system_access do
  it 'retains the behavior for normal user agents' do
    chrome_user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 \
    (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"

    expect(described_class.new(chrome_user_agent).user_agent).to be_eql(chrome_user_agent)
    expect(described_class.new(chrome_user_agent).name).to be_eql('Chrome')
  end

  it 'truncates big user agents' do
    big_user_agent = "chrome #{'abc' * 1024}"
    expect(described_class.new(big_user_agent).user_agent).not_to be_eql(big_user_agent)
  end
end
