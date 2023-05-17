# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/service_response'

RSpec.describe RuboCop::Cop::Gitlab::ServiceResponse do
  it 'does not flag the `http_status:` param on a homonym method' do
    expect_no_offenses("MyClass.error(http_status: :ok)")
  end

  it 'does not flag calls without params' do
    expect_no_offenses('ServiceResponse.error')
  end

  it 'does not flag the offense when `http_status` is not used' do
    expect_no_offenses('ServiceResponse.error(message: "some error", reason: :bad_time)')
  end

  it 'flags the use of `http_status:` parameter in ServiceResponse in error' do
    expect_offense(<<~CODE, msg: described_class::MSG)
      ServiceResponse.error(message: "some error", http_status: :bad_request)
                                                   ^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    CODE
  end

  it 'flags the use of `http_status:` parameter in ServiceResponse in success' do
    expect_offense(<<~CODE, msg: described_class::MSG)
      ServiceResponse.success(message: "some error", http_status: :bad_request)
                                                     ^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    CODE
  end

  it 'flags the use of `http_status:` parameter in ServiceResponse in initializer' do
    expect_offense(<<~CODE, msg: described_class::MSG)
      ServiceResponse.new(message: "some error", http_status: :bad_request)
                                                 ^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    CODE
  end
end
