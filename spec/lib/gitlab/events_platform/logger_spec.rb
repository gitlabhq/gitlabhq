# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EventsPlatform::Logger, feature_category: :deployment_management do
  subject(:logger) { described_class.new('/dev/null') }

  it_behaves_like 'a json logger', {}

  it 'is a JsonLogger subclass' do
    expect(described_class.superclass).to eq(::Gitlab::JsonLogger)
  end

  describe '.file_name_noext' do
    it 'writes to events_platform.log' do
      expect(described_class.file_name).to eq('events_platform.log')
    end
  end
end
