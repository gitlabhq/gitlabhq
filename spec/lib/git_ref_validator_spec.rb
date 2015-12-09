require 'spec_helper'

describe Gitlab::GitRefValidator, lib: true do
  it { expect(Gitlab::GitRefValidator.validate('feature/new')).to be_truthy }
  it { expect(Gitlab::GitRefValidator.validate('implement_@all')).to be_truthy }
  it { expect(Gitlab::GitRefValidator.validate('my_new_feature')).to be_truthy }
  it { expect(Gitlab::GitRefValidator.validate('#1')).to be_truthy }
  it { expect(Gitlab::GitRefValidator.validate('feature/~new/')).to be_falsey }
  it { expect(Gitlab::GitRefValidator.validate('feature/^new/')).to be_falsey }
  it { expect(Gitlab::GitRefValidator.validate('feature/:new/')).to be_falsey }
  it { expect(Gitlab::GitRefValidator.validate('feature/?new/')).to be_falsey }
  it { expect(Gitlab::GitRefValidator.validate('feature/*new/')).to be_falsey }
  it { expect(Gitlab::GitRefValidator.validate('feature/[new/')).to be_falsey }
  it { expect(Gitlab::GitRefValidator.validate('feature/new/')).to be_falsey }
  it { expect(Gitlab::GitRefValidator.validate('feature/new.')).to be_falsey }
  it { expect(Gitlab::GitRefValidator.validate('feature\@{')).to be_falsey }
  it { expect(Gitlab::GitRefValidator.validate('feature\new')).to be_falsey }
  it { expect(Gitlab::GitRefValidator.validate('feature//new')).to be_falsey }
  it { expect(Gitlab::GitRefValidator.validate('feature new')).to be_falsey }
end
