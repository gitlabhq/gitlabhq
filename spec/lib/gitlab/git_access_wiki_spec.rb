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

    subject { access.check('git-receive-pack', changes) }

    it { expect(subject.allowed?).to be_truthy }
  end

  def changes
    ['6f6d7e7ed 570e7b2ab refs/heads/master']
  end

  describe '#download_access_check' do
    subject { access.check('git-upload-pack', '_any') }

    before do
      project.team << [user, :developer]
    end

    context 'when wiki feature is enabled' do
      it 'give access to download wiki code' do
        project.project_feature.update_attribute(:wiki_access_level, ProjectFeature::ENABLED)

        expect(subject.allowed?).to be_truthy
      end
    end

    context 'when wiki feature is disabled' do
      it 'does not give access to download wiki code' do
        project.project_feature.update_attribute(:wiki_access_level, ProjectFeature::DISABLED)

        expect(subject.allowed?).to be_falsey
        expect(subject.message).to match(/You are not allowed to download code/)
      end
    end
  end
end
