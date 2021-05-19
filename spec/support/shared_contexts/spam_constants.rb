# frozen_string_literal: true

RSpec.shared_context 'includes Spam constants' do
  before do
    stub_const('CONDITIONAL_ALLOW', Spam::SpamConstants::CONDITIONAL_ALLOW)
    stub_const('DISALLOW', Spam::SpamConstants::DISALLOW)
    stub_const('ALLOW', Spam::SpamConstants::ALLOW)
    stub_const('BLOCK_USER', Spam::SpamConstants::BLOCK_USER)
    stub_const('NOOP', Spam::SpamConstants::NOOP)
  end
end
