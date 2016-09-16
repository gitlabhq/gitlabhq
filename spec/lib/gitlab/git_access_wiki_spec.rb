require 'spec_helper'

describe Gitlab::GitAccessWiki, lib: true do
  let(:access) { Gitlab::GitAccessWiki.new(user, project, 'web', authentication_abilities: authentication_abilities) }
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:authentication_abilities) do
    [
      :read_project,
      :download_code,
      :push_code
    ]
  end

  describe 'push_allowed?' do
    before do
      create(:protected_branch, name: 'master', project: project)
      project.team << [user, :developer]
    end

    subject { access.push_access_check(changes) }

    it { expect(subject.allowed?).to be_truthy }
  end

  def changes
    ['6f6d7e7ed 570e7b2ab refs/heads/master']
  end
end
