# frozen_string_literal: true

require 'fast_spec_helper'
require 'labkit/context'
require 'gitlab/safe_request_store'

RSpec.describe Gitlab::AppLogger, feature_category: :observability do
  subject { described_class }

  specify { expect(described_class.primary_logger).to be Gitlab::AppJsonLogger }

  it 'logs to AppJsonLogger' do
    expect_any_instance_of(Gitlab::AppJsonLogger).to receive(:info).and_call_original

    subject.info('Hello World!')
  end
end
