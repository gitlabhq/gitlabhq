# frozen_string_literal: true

shared_context 'includes Spam constants' do
  before do
    stub_const('REQUIRE_RECAPTCHA', Spam::SpamConstants::REQUIRE_RECAPTCHA)
    stub_const('DISALLOW', Spam::SpamConstants::DISALLOW)
    stub_const('ALLOW', Spam::SpamConstants::ALLOW)
    stub_const('BLOCK_USER', Spam::SpamConstants::BLOCK_USER)
  end
end
