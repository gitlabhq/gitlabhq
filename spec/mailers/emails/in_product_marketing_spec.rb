# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::InProductMarketing do
  it 'has correct custom headers' do
    expect(described_class::FROM_ADDRESS).to be('GitLab <team@gitlab.com>')
    expect(described_class::CUSTOM_HEADERS).to eq({
      from: 'GitLab <team@gitlab.com>',
      reply_to: 'GitLab <team@gitlab.com>',
      'X-Mailgun-Track' => 'yes',
      'X-Mailgun-Track-Clicks' => 'yes',
      'X-Mailgun-Track-Opens' => 'yes',
      'X-Mailgun-Tag' => 'marketing'
    })
  end
end
