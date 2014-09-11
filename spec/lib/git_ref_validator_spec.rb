require 'spec_helper'

describe Gitlab::GitRefValidator do
  it { Gitlab::GitRefValidator.validate('feature/new').should be_true }
  it { Gitlab::GitRefValidator.validate('implement_@all').should be_true }
  it { Gitlab::GitRefValidator.validate('my_new_feature').should be_true }
  it { Gitlab::GitRefValidator.validate('#1').should be_true }
  it { Gitlab::GitRefValidator.validate('feature/~new/').should be_false }
  it { Gitlab::GitRefValidator.validate('feature/^new/').should be_false }
  it { Gitlab::GitRefValidator.validate('feature/:new/').should be_false }
  it { Gitlab::GitRefValidator.validate('feature/?new/').should be_false }
  it { Gitlab::GitRefValidator.validate('feature/*new/').should be_false }
  it { Gitlab::GitRefValidator.validate('feature/[new/').should be_false }
  it { Gitlab::GitRefValidator.validate('feature/new/').should be_false }
  it { Gitlab::GitRefValidator.validate('feature/new.').should be_false }
  it { Gitlab::GitRefValidator.validate('feature\@{').should be_false }
  it { Gitlab::GitRefValidator.validate('feature\new').should be_false }
  it { Gitlab::GitRefValidator.validate('feature//new').should be_false }
  it { Gitlab::GitRefValidator.validate('feature new').should be_false }
end
