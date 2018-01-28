require 'spec_helper'

describe Gitlab::GitRefValidator do
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
  it { expect(described_class.validate('.tag')).to be_falsey }
  it { expect(described_class.validate('my branch')).to be_falsey }
end
