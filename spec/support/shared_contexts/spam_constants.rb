# frozen_string_literal: true

shared_context 'includes Spam constants' do
  REQUIRE_RECAPTCHA = Spam::SpamConstants::REQUIRE_RECAPTCHA
  DISALLOW = Spam::SpamConstants::DISALLOW
  ALLOW = Spam::SpamConstants::ALLOW
end
