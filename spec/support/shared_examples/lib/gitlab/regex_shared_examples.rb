# frozen_string_literal: true

RSpec.shared_examples 'regex rejecting path traversal' do
  it { is_expected.not_to match('a../b') }
  it { is_expected.not_to match('a..%2fb') }
  it { is_expected.not_to match('a%2e%2e%2fb') }
  it { is_expected.not_to match('a%2e%2e/b') }
end
