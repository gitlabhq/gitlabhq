# frozen_string_literal: true

RSpec.shared_context 'includes Spam constants' do
  before do
    stub_const('BLOCK_USER', Spam::SpamConstants::BLOCK_USER)
    stub_const('DISALLOW', Spam::SpamConstants::DISALLOW)
    stub_const('CONDITIONAL_ALLOW', Spam::SpamConstants::CONDITIONAL_ALLOW)
    stub_const('OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM', Spam::SpamConstants::OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM)
    stub_const('ALLOW', Spam::SpamConstants::ALLOW)
    stub_const('NOOP', Spam::SpamConstants::NOOP)
  end
end
