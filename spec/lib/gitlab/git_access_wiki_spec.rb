# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitAccessWiki do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :wiki_repo) }
  let_it_be(:wiki) { create(:project_wiki, project: project) }

  let(:changes) { ['6f6d7e7ed 570e7b2ab refs/heads/master'] }
  let(:authentication_abilities) { %i[read_project download_code push_code] }
  let(:redirected_path) { nil }

  let(:access) do
    described_class.new(user, wiki, 'web',
                        authentication_abilities: authentication_abilities,
                        redirected_path: redirected_path)
  end

  describe '#push_access_check' do
    subject { access.check('git-receive-pack', changes) }

    context 'when user can :create_wiki' do
      before do
        project.add_developer(user)
      end

      it { expect { subject }.not_to raise_error }

      context 'when in a read-only GitLab instance' do
        let(:message) { "You can't push code to a read-only GitLab instance." }

        before do
          allow(Gitlab::Database.main).to receive(:read_only?) { true }
        end

        it_behaves_like 'forbidden git access'
      end
    end

    context 'the user cannot :create_wiki' do
      it_behaves_like 'not-found git access' do
        let(:message) { 'The wiki you were looking for could not be found.' }
      end
    end
  end

  describe '#check_download_access!' do
    subject { access.check('git-upload-pack', Gitlab::GitAccess::ANY) }

    context 'the user can :download_wiki_code' do
      before do
        project.add_developer(user)
      end

      context 'when wiki feature is disabled' do
        before do
          project.project_feature.update_attribute(:wiki_access_level, ProjectFeature::DISABLED)
        end

        it_behaves_like 'forbidden git access' do
          let(:message) { include('wiki') }
        end
      end

      context 'when the repository does not exist' do
        before do
          allow(wiki.repository).to receive(:exists?).and_return(false)
        end

        it_behaves_like 'not-found git access' do
          let(:message) { include('for this wiki') }
        end
      end
    end

    context 'the user cannot :download_wiki_code' do
      it_behaves_like 'not-found git access' do
        let(:message) { include('wiki') }
      end
    end
  end
end
