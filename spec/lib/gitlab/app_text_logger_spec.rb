# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AppTextLogger do
  subject { described_class.new('/dev/null') }

  let(:hash_message) { { message: 'Message', project_id: 123 } }
  let(:string_message) { 'Information' }

  it 'logs a hash as string' do
    expect(subject.format_message('INFO', Time.now, nil, hash_message)).to include(hash_message.to_s)
  end

  it 'logs a string unchanged' do
    expect(subject.format_message('INFO', Time.now, nil, string_message)).to include(string_message)
  end

  it 'logs time in UTC with ISO8601.3 standard' do
    freeze_time do
      expect(subject.format_message('INFO', Time.now, nil, string_message))
        .to include(Time.now.utc.iso8601(3))
    end
  end
end
