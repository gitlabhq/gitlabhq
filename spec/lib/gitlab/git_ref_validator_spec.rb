require 'spec_helper'

describe Gitlab::GitRefValidator do
  using RSpec::Parameterized::TableSyntax

  context '.validate' do
    it { expect(described_class.validate('feature/new')).to be_truthy }
    it { expect(described_class.validate('implement_@all')).to be_truthy }
    it { expect(described_class.validate('my_new_feature')).to be_truthy }
    it { expect(described_class.validate('my-branch')).to be_truthy }
    it { expect(described_class.validate('#1')).to be_truthy }
    it { expect(described_class.validate('feature/refs/heads/foo')).to be_truthy }
    it { expect(described_class.validate('feature/~new/')).to be_falsey }
    it { expect(described_class.validate('feature/^new/')).to be_falsey }
    it { expect(described_class.validate('feature/:new/')).to be_falsey }
    it { expect(described_class.validate('feature/?new/')).to be_falsey }
    it { expect(described_class.validate('feature/*new/')).to be_falsey }
    it { expect(described_class.validate('feature/[new/')).to be_falsey }
    it { expect(described_class.validate('feature/new/')).to be_falsey }
    it { expect(described_class.validate('feature/new.')).to be_falsey }
    it { expect(described_class.validate('feature\@{')).to be_falsey }
    it { expect(described_class.validate('feature\new')).to be_falsey }
    it { expect(described_class.validate('feature//new')).to be_falsey }
    it { expect(described_class.validate('feature new')).to be_falsey }
    it { expect(described_class.validate('refs/heads/')).to be_falsey }
    it { expect(described_class.validate('refs/remotes/')).to be_falsey }
    it { expect(described_class.validate('refs/heads/feature')).to be_falsey }
    it { expect(described_class.validate('refs/remotes/origin')).to be_falsey }
    it { expect(described_class.validate('-')).to be_falsey }
    it { expect(described_class.validate('-branch')).to be_falsey }
    it { expect(described_class.validate('+foo:bar')).to be_falsey }
    it { expect(described_class.validate('foo:bar')).to be_falsey }
    it { expect(described_class.validate('.tag')).to be_falsey }
    it { expect(described_class.validate('my branch')).to be_falsey }
    it { expect(described_class.validate("\xA0\u0000\xB0")).to be_falsey }
  end

  context '.validate_merge_request_branch' do
    it { expect(described_class.validate_merge_request_branch('HEAD')).to be_truthy }
    it { expect(described_class.validate_merge_request_branch('feature/new')).to be_truthy }
    it { expect(described_class.validate_merge_request_branch('implement_@all')).to be_truthy }
    it { expect(described_class.validate_merge_request_branch('my_new_feature')).to be_truthy }
    it { expect(described_class.validate_merge_request_branch('my-branch')).to be_truthy }
    it { expect(described_class.validate_merge_request_branch('#1')).to be_truthy }
    it { expect(described_class.validate_merge_request_branch('feature/refs/heads/foo')).to be_truthy }
    it { expect(described_class.validate_merge_request_branch('feature/~new/')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('feature/^new/')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('feature/:new/')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('feature/?new/')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('feature/*new/')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('feature/[new/')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('feature/new/')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('feature/new.')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('feature\@{')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('feature\new')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('feature//new')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('feature new')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('refs/heads/master')).to be_truthy }
    it { expect(described_class.validate_merge_request_branch('refs/heads/')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('refs/remotes/')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('-')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('-branch')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('+foo:bar')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('foo:bar')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('.tag')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch('my branch')).to be_falsey }
    it { expect(described_class.validate_merge_request_branch("\xA0\u0000\xB0")).to be_falsey }
  end
end
