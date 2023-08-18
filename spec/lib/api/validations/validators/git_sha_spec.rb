# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::GitSha do
  include ApiValidatorsHelpers

  let(:sha) { RepoHelpers.sample_commit.id }
  let(:short_sha) { sha[0, Gitlab::Git::Commit::MIN_SHA_LENGTH] }
  let(:too_short_sha) { sha[0, Gitlab::Git::Commit::MIN_SHA_LENGTH - 1] }
  let(:too_long_sha) { "a" * (Gitlab::Git::Commit::MAX_SHA_LENGTH + 1) }

  subject do
    described_class.new(['test'], {}, false, scope.new)
  end

  context 'valid sha' do
    it 'does not raise a validation error' do
      expect_no_validation_error('test' => sha)
      expect_no_validation_error('test' => short_sha)
    end
  end

  context 'empty params' do
    it 'raises a validation error' do
      expect_validation_error('test' => nil)
      expect_validation_error('test' => '')
    end
  end

  context 'invalid sha' do
    it 'raises a validation error' do
      expect_validation_error('test' => too_long_sha) # too long SHA
      expect_validation_error('test' => 'somestring')
      expect_validation_error('test' => too_short_sha) # sha length < MIN_SHA_LENGTH (7)
    end
  end
end
