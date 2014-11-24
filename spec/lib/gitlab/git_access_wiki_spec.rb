require 'spec_helper'

describe Gitlab::GitAccessWiki do
  let(:access) { Gitlab::GitAccessWiki.new }
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  describe 'push_allowed?' do
    before do
      create(:protected_branch, name: 'master', project: project)
      project.team << [user, :developer]
    end

    subject { access.push_access_check(user, project, changes) }

    it { subject.allowed?.should be_true }
  end

  def changes
    ['6f6d7e7ed 570e7b2ab refs/heads/master']
  end
end
