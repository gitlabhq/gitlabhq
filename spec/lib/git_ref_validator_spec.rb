require 'spec_helper'

describe Gitlab::GitRefValidator do
  it { expect(Gitlab::GitRefValidator.validate('feature/new')).to be_true }
  it { expect(Gitlab::GitRefValidator.validate('implement_@all')).to be_true }
  it { expect(Gitlab::GitRefValidator.validate('my_new_feature')).to be_true }
  it { expect(Gitlab::GitRefValidator.validate('#1')).to be_true }
  it { expect(Gitlab::GitRefValidator.validate('feature/~new/')).to be_false }
  it { expect(Gitlab::GitRefValidator.validate('feature/^new/')).to be_false }
  it { expect(Gitlab::GitRefValidator.validate('feature/:new/')).to be_false }
  it { expect(Gitlab::GitRefValidator.validate('feature/?new/')).to be_false }
  it { expect(Gitlab::GitRefValidator.validate('feature/*new/')).to be_false }
  it { expect(Gitlab::GitRefValidator.validate('feature/[new/')).to be_false }
  it { expect(Gitlab::GitRefValidator.validate('feature/new/')).to be_false }
  it { expect(Gitlab::GitRefValidator.validate('feature/new.')).to be_false }
  it { expect(Gitlab::GitRefValidator.validate('feature\@{')).to be_false }
  it { expect(Gitlab::GitRefValidator.validate('feature\new')).to be_false }
  it { expect(Gitlab::GitRefValidator.validate('feature//new')).to be_false }
  it { expect(Gitlab::GitRefValidator.validate('feature new')).to be_false }
end
