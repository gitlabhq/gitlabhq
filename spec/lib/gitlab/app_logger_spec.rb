# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AppLogger do
  subject { described_class }

  it 'logs info to only the AppJsonLogger when unstructured logs are disabled' do
    expect_any_instance_of(Gitlab::AppTextLogger).not_to receive(:info).and_call_original
    expect_any_instance_of(Gitlab::AppJsonLogger).to receive(:info).and_call_original

    subject.info('Hello World!')
  end
end
