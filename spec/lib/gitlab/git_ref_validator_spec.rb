# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GitRefValidator do
  using RSpec::Parameterized::TableSyntax

  context '.validate' do
    it { expect(described_class.validate('feature/new')).to be true }
    it { expect(described_class.validate('implement_@all')).to be true }
    it { expect(described_class.validate('my_new_feature')).to be true }
    it { expect(described_class.validate('my-branch')).to be true }
    it { expect(described_class.validate('#1')).to be true }
    it { expect(described_class.validate('feature/refs/heads/foo')).to be true }
    it { expect(described_class.validate('feature/~new/')).to be false }
    it { expect(described_class.validate('feature/^new/')).to be false }
    it { expect(described_class.validate('feature/:new/')).to be false }
    it { expect(described_class.validate('feature/?new/')).to be false }
    it { expect(described_class.validate('feature/*new/')).to be false }
    it { expect(described_class.validate('feature/[new/')).to be false }
    it { expect(described_class.validate('feature/new/')).to be false }
    it { expect(described_class.validate('feature/new.')).to be false }
    it { expect(described_class.validate('feature\@{')).to be false }
    it { expect(described_class.validate('feature\new')).to be false }
    it { expect(described_class.validate('feature//new')).to be false }
    it { expect(described_class.validate('feature new')).to be false }
    it { expect(described_class.validate('refs/heads/')).to be false }
    it { expect(described_class.validate('refs/remotes/')).to be false }
    it { expect(described_class.validate('refs/heads/feature')).to be false }
    it { expect(described_class.validate('refs/remotes/origin')).to be false }
    it { expect(described_class.validate('-')).to be false }
    it { expect(described_class.validate('-branch')).to be false }
    it { expect(described_class.validate('+foo:bar')).to be false }
    it { expect(described_class.validate('foo:bar')).to be false }
    it { expect(described_class.validate('.tag')).to be false }
    it { expect(described_class.validate('my branch')).to be false }
    it { expect(described_class.validate("\xA0\u0000\xB0")).to be false }
  end

  context '.validate_merge_request_branch' do
    it { expect(described_class.validate_merge_request_branch('HEAD')).to be true }
    it { expect(described_class.validate_merge_request_branch('feature/new')).to be true }
    it { expect(described_class.validate_merge_request_branch('implement_@all')).to be true }
    it { expect(described_class.validate_merge_request_branch('my_new_feature')).to be true }
    it { expect(described_class.validate_merge_request_branch('my-branch')).to be true }
    it { expect(described_class.validate_merge_request_branch('#1')).to be true }
    it { expect(described_class.validate_merge_request_branch('feature/refs/heads/foo')).to be true }
    it { expect(described_class.validate_merge_request_branch('feature/~new/')).to be false }
    it { expect(described_class.validate_merge_request_branch('feature/^new/')).to be false }
    it { expect(described_class.validate_merge_request_branch('feature/:new/')).to be false }
    it { expect(described_class.validate_merge_request_branch('feature/?new/')).to be false }
    it { expect(described_class.validate_merge_request_branch('feature/*new/')).to be false }
    it { expect(described_class.validate_merge_request_branch('feature/[new/')).to be false }
    it { expect(described_class.validate_merge_request_branch('feature/new/')).to be false }
    it { expect(described_class.validate_merge_request_branch('feature/new.')).to be false }
    it { expect(described_class.validate_merge_request_branch('feature\@{')).to be false }
    it { expect(described_class.validate_merge_request_branch('feature\new')).to be false }
    it { expect(described_class.validate_merge_request_branch('feature//new')).to be false }
    it { expect(described_class.validate_merge_request_branch('feature new')).to be false }
    it { expect(described_class.validate_merge_request_branch('refs/heads/master')).to be true }
    it { expect(described_class.validate_merge_request_branch('refs/heads/')).to be false }
    it { expect(described_class.validate_merge_request_branch('refs/remotes/')).to be false }
    it { expect(described_class.validate_merge_request_branch('-')).to be false }
    it { expect(described_class.validate_merge_request_branch('-branch')).to be false }
    it { expect(described_class.validate_merge_request_branch('+foo:bar')).to be false }
    it { expect(described_class.validate_merge_request_branch('foo:bar')).to be false }
    it { expect(described_class.validate_merge_request_branch('.tag')).to be false }
    it { expect(described_class.validate_merge_request_branch('my branch')).to be false }
    it { expect(described_class.validate_merge_request_branch("\xA0\u0000\xB0")).to be false }
  end
end
