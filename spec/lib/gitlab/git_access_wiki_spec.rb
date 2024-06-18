# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitAccessWiki do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :wiki_repo) }

  let(:wiki) { create(:project_wiki, project: project) }

  let(:changes) { ['6f6d7e7ed 570e7b2ab refs/heads/master'] }
  let(:authentication_abilities) { %i[read_project download_code push_code] }
  let(:redirected_path) { nil }

  let(:access) do
    described_class.new(user, wiki, 'web',
      authentication_abilities: authentication_abilities,
      redirected_path: redirected_path)
  end

  RSpec.shared_examples 'download wiki access by level' do
    where(:project_visibility, :project_member?, :wiki_access_level, :wiki_repo?, :expected_behavior) do
      [
        # Private project - is a project member
        [Gitlab::VisibilityLevel::PRIVATE, true, ProjectFeature::ENABLED, true, :no_error],
        [Gitlab::VisibilityLevel::PRIVATE, true, ProjectFeature::PRIVATE, true, :no_error],
        [Gitlab::VisibilityLevel::PRIVATE, true, ProjectFeature::DISABLED, true, :forbidden_wiki],
        [Gitlab::VisibilityLevel::PRIVATE, true, ProjectFeature::ENABLED, false, :not_found_wiki],
        [Gitlab::VisibilityLevel::PRIVATE, true, ProjectFeature::DISABLED, false, :not_found_wiki],
        [Gitlab::VisibilityLevel::PRIVATE, true, ProjectFeature::PRIVATE, false, :not_found_wiki],
        # Private project - is NOT a project member
        [Gitlab::VisibilityLevel::PRIVATE, false, ProjectFeature::ENABLED, true, :not_found_wiki],
        [Gitlab::VisibilityLevel::PRIVATE, false, ProjectFeature::PRIVATE, true, :not_found_wiki],
        [Gitlab::VisibilityLevel::PRIVATE, false, ProjectFeature::DISABLED, true, :not_found_wiki],
        [Gitlab::VisibilityLevel::PRIVATE, false, ProjectFeature::ENABLED, false, :not_found_wiki],
        [Gitlab::VisibilityLevel::PRIVATE, false, ProjectFeature::DISABLED, false, :not_found_wiki],
        [Gitlab::VisibilityLevel::PRIVATE, false, ProjectFeature::PRIVATE, false, :not_found_wiki],
        # Public project - is a project member
        [Gitlab::VisibilityLevel::PUBLIC, true, ProjectFeature::ENABLED, true, :no_error],
        [Gitlab::VisibilityLevel::PUBLIC, true, ProjectFeature::PRIVATE, true, :no_error],
        [Gitlab::VisibilityLevel::PUBLIC, true, ProjectFeature::DISABLED, true, :forbidden_wiki],
        [Gitlab::VisibilityLevel::PUBLIC, true, ProjectFeature::ENABLED, false, :not_found_wiki],
        [Gitlab::VisibilityLevel::PUBLIC, true, ProjectFeature::DISABLED, false, :not_found_wiki],
        [Gitlab::VisibilityLevel::PUBLIC, true, ProjectFeature::PRIVATE, false, :not_found_wiki],
        # Public project - is NOT a project member
        [Gitlab::VisibilityLevel::PUBLIC, false, ProjectFeature::ENABLED, true, :no_error],
        [Gitlab::VisibilityLevel::PUBLIC, false, ProjectFeature::PRIVATE, true, :forbidden_wiki],
        [Gitlab::VisibilityLevel::PUBLIC, false, ProjectFeature::DISABLED, true, :forbidden_wiki],
        [Gitlab::VisibilityLevel::PUBLIC, false, ProjectFeature::ENABLED, false, :not_found_wiki],
        [Gitlab::VisibilityLevel::PUBLIC, false, ProjectFeature::DISABLED, false, :not_found_wiki],
        [Gitlab::VisibilityLevel::PUBLIC, false, ProjectFeature::PRIVATE, false, :not_found_wiki]
      ]
    end

    with_them do
      before do
        project.update!(visibility_level: project_visibility)
        project.add_developer(user) if project_member?
        project.project_feature.update_attribute(:wiki_access_level, wiki_access_level)
        allow(wiki.repository).to receive(:exists?).and_return(wiki_repo?)
      end

      it 'provides access by level' do
        case expected_behavior
        when :no_error
          expect { subject }.not_to raise_error
        when :forbidden_wiki
          expect { subject }.to raise_wiki_forbidden
        when :not_found_wiki
          expect { subject }.to raise_wiki_not_found
        end
      end
    end
  end

  describe '#push_access_check' do
    subject { access.check('git-receive-pack', changes) }

    context 'when user can :create_wiki' do
      before do
        project.add_developer(user)
      end

      it { expect { subject }.not_to raise_error }

      context 'when in a read-only GitLab instance' do
        before do
          allow(Gitlab::Database).to receive(:read_only?) { true }
        end

        it_behaves_like 'forbidden git access' do
          let(:message) { "You can't push code to a read-only GitLab instance." }
        end
      end
    end

    context 'the user cannot :create_wiki' do
      it { expect { subject }.to raise_wiki_not_found }
    end
  end

  describe '#check_download_access!' do
    subject { access.check('git-upload-pack', Gitlab::GitAccess::ANY) }

    context 'when actor is a user' do
      it_behaves_like 'download wiki access by level'
    end

    context 'when the actor is a deploy token' do
      let_it_be(:actor) { create(:deploy_token, projects: [project]) }
      let_it_be(:user) { actor }

      before do
        project.project_feature.update_attribute(:wiki_access_level, wiki_access_level)
      end

      subject { access.check('git-upload-pack', changes) }

      context 'when the wiki feature is enabled' do
        let(:wiki_access_level) { ProjectFeature::ENABLED }

        it { expect { subject }.not_to raise_error }
      end

      context 'when the wiki feature is disabled' do
        let(:wiki_access_level) { ProjectFeature::DISABLED }

        it { expect { subject }.to raise_wiki_forbidden }
      end

      context 'when the wiki feature is private' do
        let(:wiki_access_level) { ProjectFeature::PRIVATE }

        it { expect { subject }.to raise_wiki_forbidden }
      end
    end

    context 'when the actor is a deploy key' do
      let_it_be(:actor) { create(:deploy_key) }
      let_it_be(:deploy_key_project) { create(:deploy_keys_project, project: project, deploy_key: actor) }
      let_it_be(:user) { actor }

      before do
        project.project_feature.update_attribute(:wiki_access_level, wiki_access_level)
      end

      subject { access.check('git-upload-pack', changes) }

      context 'when the wiki is enabled' do
        let(:wiki_access_level) { ProjectFeature::ENABLED }

        it { expect { subject }.not_to raise_error }
      end

      context 'when the wiki is disabled' do
        let(:wiki_access_level) { ProjectFeature::DISABLED }

        it { expect { subject }.to raise_wiki_forbidden }
      end
    end

    describe 'when actor is a user provided by build via CI_JOB_TOKEN' do
      let(:protocol) { 'http' }
      let(:authentication_abilities) { [:build_download_code] }
      let(:auth_result_type) { :build }

      before do
        project.project_feature.update_attribute(:wiki_access_level, wiki_access_level)
      end

      subject { access.check('git-upload-pack', changes) }

      it_behaves_like 'download wiki access by level'
    end
  end

  RSpec::Matchers.define :raise_wiki_not_found do
    match do |actual|
      expect { actual.call }.to raise_error(Gitlab::GitAccess::NotFoundError, include('wiki'))
    end
    def supports_block_expectations?
      true
    end
  end

  RSpec::Matchers.define :raise_wiki_forbidden do
    match do |actual|
      expect { subject }.to raise_error(Gitlab::GitAccess::ForbiddenError, include('wiki'))
    end
    def supports_block_expectations?
      true
    end
  end
end
