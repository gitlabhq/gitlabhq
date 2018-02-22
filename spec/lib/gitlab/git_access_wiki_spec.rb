require 'spec_helper'

describe Gitlab::GitAccessWiki do
  let(:access) { described_class.new(user, project, 'web', authentication_abilities: authentication_abilities, redirected_path: redirected_path) }
  let(:project) { create(:project, :wiki_repo) }
  let(:user) { create(:user) }
  let(:changes) { ['6f6d7e7ed 570e7b2ab refs/heads/master'] }
  let(:redirected_path) { nil }
  let(:authentication_abilities) do
    [
      :read_project,
      :download_code,
      :push_code
    ]
  end

  describe '#push_access_check' do
    context 'when user can :create_wiki' do
      before do
        create(:protected_branch, name: 'master', project: project)
        project.add_developer(user)
      end

      subject { access.check('git-receive-pack', changes) }

      it { expect { subject }.not_to raise_error }

      context 'when in a read-only GitLab instance' do
        before do
          allow(Gitlab::Database).to receive(:read_only?) { true }
        end

        it 'does not give access to upload wiki code' do
          expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "You can't push code to a read-only GitLab instance.")
        end
      end
    end
  end

  describe '#access_check_download!' do
    subject { access.check('git-upload-pack', '_any') }

    before do
      project.add_developer(user)
    end

    context 'when wiki feature is enabled' do
      it 'give access to download wiki code' do
        expect { subject }.not_to raise_error
      end

      context 'when the wiki repository does not exist' do
        it 'returns not found' do
          wiki_repo = project.wiki.repository
          FileUtils.rm_rf(wiki_repo.path)

          # Sanity check for rm_rf
          expect(wiki_repo.exists?).to eq(false)

          expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'A repository for this project does not exist yet.')
        end
      end
    end

    context 'when wiki feature is disabled' do
      it 'does not give access to download wiki code' do
        project.project_feature.update_attribute(:wiki_access_level, ProjectFeature::DISABLED)

        expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You are not allowed to download code from this project.')
      end
    end
  end
end
