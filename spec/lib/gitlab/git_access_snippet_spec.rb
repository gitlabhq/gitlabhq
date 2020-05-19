# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GitAccessSnippet do
  include ProjectHelpers
  include TermsHelper
  include_context 'ProjectPolicyTable context'
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:snippet) { create(:project_snippet, :public, :repository, project: project) }
  let_it_be(:migration_bot) { User.migration_bot }

  let(:repository) { snippet.repository }
  let(:actor) { user }
  let(:protocol) { 'ssh' }
  let(:changes) { Gitlab::GitAccess::ANY }
  let(:authentication_abilities) { [:download_code, :push_code] }

  let(:push_access_check) { access.check('git-receive-pack', changes) }
  let(:pull_access_check) { access.check('git-upload-pack', changes) }

  subject(:access) { Gitlab::GitAccessSnippet.new(actor, snippet, protocol, authentication_abilities: authentication_abilities) }

  describe 'when actor is a DeployKey' do
    let(:actor) { build(:deploy_key) }

    it 'does not allow push and pull access' do
      expect { push_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:authentication_mechanism])
      expect { pull_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:authentication_mechanism])
    end
  end

  shared_examples 'actor is migration bot' do
    context 'when user is the migration bot' do
      let(:user) { migration_bot }

      it 'can perform git operations' do
        expect { push_access_check }.not_to raise_error
        expect { pull_access_check }.not_to raise_error
      end
    end
  end

  describe '#check_snippet_accessibility!' do
    context 'when the snippet exists' do
      it 'allows access' do
        project.add_developer(actor)

        expect { pull_access_check }.not_to raise_error
      end
    end

    context 'when the snippet is nil' do
      let(:snippet) { nil }

      it 'blocks access with "not found"' do
        expect { pull_access_check }.to raise_snippet_not_found
      end
    end

    context 'when the snippet does not have a repository' do
      let(:snippet) { build_stubbed(:personal_snippet) }

      it 'blocks access with "not found"' do
        expect { pull_access_check }.to raise_snippet_not_found
      end
    end
  end

  context 'terms are enforced', :aggregate_failures do
    before do
      enforce_terms
    end

    let(:user) { snippet.author }

    it 'blocks access when the user did not accept terms' do
      message = /must accept the Terms of Service in order to perform this action/

      expect { push_access_check }.to raise_forbidden(message)
      expect { pull_access_check }.to raise_forbidden(message)
    end

    it 'allows access when the user accepted the terms' do
      accept_terms(user)

      expect { push_access_check }.not_to raise_error
      expect { pull_access_check }.not_to raise_error
    end

    it_behaves_like 'actor is migration bot' do
      before do
        expect(migration_bot.required_terms_not_accepted?).to be_truthy
      end
    end
  end

  context 'project snippet accessibility', :aggregate_failures do
    let(:snippet) { create(:project_snippet, :private, :repository, project: project) }
    let(:user) { membership == :author ? snippet.author : create_user_from_membership(project, membership) }

    shared_examples_for 'checks accessibility' do
      [:anonymous, :non_member, :guest, :reporter, :maintainer, :admin, :author].each do |membership|
        context membership.to_s do
          let(:membership) { membership }

          it 'respects accessibility' do
            if Ability.allowed?(user, :update_snippet, snippet)
              expect { push_access_check }.not_to raise_error
            else
              expect { push_access_check }.to raise_error(described_class::ForbiddenError)
            end

            if Ability.allowed?(user, :read_snippet, snippet)
              expect { pull_access_check }.not_to raise_error
            else
              expect { pull_access_check }.to raise_error(described_class::ForbiddenError)
            end
          end
        end
      end
    end

    context 'when project is public' do
      it_behaves_like 'checks accessibility'
      it_behaves_like 'actor is migration bot'
    end

    context 'when project is public but snippet feature is private' do
      let(:project) { create(:project, :public) }

      before do
        update_feature_access_level(project, :private)
      end

      it_behaves_like 'checks accessibility'
      it_behaves_like 'actor is migration bot'
    end

    context 'when project is not accessible' do
      let(:project) { create(:project, :private) }

      [:anonymous, :non_member].each do |membership|
        context membership.to_s do
          let(:membership) { membership }

          it 'respects accessibility' do
            expect { push_access_check }.to raise_snippet_not_found
            expect { pull_access_check }.to raise_snippet_not_found
          end
        end
      end

      it_behaves_like 'actor is migration bot'
    end

    context 'when project is archived' do
      let(:project) { create(:project, :public, :archived) }

      [:anonymous, :non_member].each do |membership|
        context membership.to_s do
          let(:membership) { membership }

          it 'cannot perform git operations' do
            expect { push_access_check }.to raise_error(described_class::ForbiddenError)
            expect { pull_access_check }.to raise_error(described_class::ForbiddenError)
          end
        end
      end

      [:guest, :reporter, :maintainer, :author, :admin].each do |membership|
        context membership.to_s do
          let(:membership) { membership }

          it 'cannot perform git pushes' do
            expect { push_access_check }.to raise_error(described_class::ForbiddenError)
            expect { pull_access_check }.not_to raise_error
          end
        end
      end

      it_behaves_like 'actor is migration bot'
    end

    context 'when snippet feature is disabled' do
      let(:project) { create(:project, :public, :snippets_disabled) }

      [:anonymous, :non_member, :author, :admin].each do |membership|
        context membership.to_s do
          let(:membership) { membership }

          it 'cannot perform git operations' do
            expect { push_access_check }.to raise_error(described_class::ForbiddenError)
            expect { pull_access_check }.to raise_error(described_class::ForbiddenError)
          end
        end
      end

      it_behaves_like 'actor is migration bot'
    end
  end

  context 'personal snippet accessibility', :aggregate_failures do
    let(:snippet) { create(:personal_snippet, snippet_level, :repository) }
    let(:user) { membership == :author ? snippet.author : create_user_from_membership(nil, membership) }

    where(:snippet_level, :membership, :_expected_count) do
      permission_table_for_personal_snippet_access
    end

    with_them do
      it "respects accessibility" do
        error_class = described_class::ForbiddenError

        if Ability.allowed?(user, :update_snippet, snippet)
          expect { push_access_check }.not_to raise_error
        else
          expect { push_access_check }.to raise_error(error_class)
        end

        if Ability.allowed?(user, :read_snippet, snippet)
          expect { pull_access_check }.not_to raise_error
        else
          expect { pull_access_check }.to raise_error(error_class)
        end
      end

      it_behaves_like 'actor is migration bot'
    end
  end

  context 'when geo is enabled', if: Gitlab.ee? do
    let(:user) { snippet.author }
    let!(:primary_node) { FactoryBot.create(:geo_node, :primary) }

    before do
      allow(::Gitlab::Database).to receive(:read_only?).and_return(true)
      allow(::Gitlab::Geo).to receive(:secondary_with_primary?).and_return(true)
    end

    # Without override, push access would return Gitlab::GitAccessResult::CustomAction
    it 'skips geo for snippet' do
      expect { push_access_check }.to raise_forbidden(/You can't push code to a read-only GitLab instance/)
    end

    context 'when user is migration bot' do
      let(:user) { migration_bot }

      it 'skips geo for snippet' do
        expect { push_access_check }.to raise_forbidden(/You can't push code to a read-only GitLab instance/)
      end
    end
  end

  context 'when changes are specific' do
    let(:changes) { "2d1db523e11e777e49377cfb22d368deec3f0793 ddd0f15ae83993f5cb66a927a28673882e99100b master" }
    let(:user) { snippet.author }

    shared_examples 'snippet checks' do
      it 'does not raise error if SnippetCheck does not raise error' do
        expect_next_instance_of(Gitlab::Checks::SnippetCheck) do |check|
          expect(check).to receive(:validate!).and_call_original
        end
        expect_next_instance_of(Gitlab::Checks::PushFileCountCheck) do |check|
          expect(check).to receive(:validate!)
        end

        expect { push_access_check }.not_to raise_error
      end

      it 'raises error if SnippetCheck raises error' do
        expect_next_instance_of(Gitlab::Checks::SnippetCheck) do |check|
          allow(check).to receive(:validate!).and_raise(Gitlab::GitAccess::ForbiddenError, 'foo')
        end

        expect { push_access_check }.to raise_forbidden('foo')
      end

      it 'sets the file count limit from Snippet class' do
        service = double

        expect(service).to receive(:validate!).and_return(nil)
        expect(Snippet).to receive(:max_file_limit).with(user).and_return(5)
        expect(Gitlab::Checks::PushFileCountCheck).to receive(:new).with(anything, hash_including(limit: 5)).and_return(service)

        push_access_check
      end
    end

    it_behaves_like 'snippet checks'

    context 'when user is migration bot' do
      let(:user) { migration_bot }

      it_behaves_like 'snippet checks'
    end
  end

  describe 'repository size restrictions' do
    let(:snippet) { create(:personal_snippet, :public, :repository) }
    let(:actor) { snippet.author }

    let(:oldrev) { TestEnv::BRANCH_SHA["snippet/single-file"] }
    let(:newrev) { TestEnv::BRANCH_SHA["snippet/edit-file"] }
    let(:ref) { "refs/heads/snippet/edit-file" }
    let(:changes) { "#{oldrev} #{newrev} #{ref}" }

    shared_examples 'migration bot does not err' do
      let(:actor) { migration_bot }

      it 'does not err' do
        expect(snippet.repository_size_checker).not_to receive(:above_size_limit?)

        expect { push_access_check }.not_to raise_error
      end
    end

    shared_examples_for 'a push to repository already over the limit' do
      it 'errs' do
        expect(snippet.repository_size_checker).to receive(:above_size_limit?).and_return(true)

        expect do
          push_access_check
        end.to raise_error(described_class::ForbiddenError, /Your push has been rejected/)
      end

      it_behaves_like 'migration bot does not err'
    end

    shared_examples_for 'a push to repository below the limit' do
      it 'does not err' do
        expect(snippet.repository_size_checker).to receive(:above_size_limit?).and_return(false)
        expect(snippet.repository_size_checker)
          .to receive(:changes_will_exceed_size_limit?)
            .with(change_size)
            .and_return(false)

        expect { push_access_check }.not_to raise_error
      end

      it_behaves_like 'migration bot does not err'
    end

    shared_examples_for 'a push to repository to make it over the limit' do
      it 'errs' do
        expect(snippet.repository_size_checker).to receive(:above_size_limit?).and_return(false)
        expect(snippet.repository_size_checker)
          .to receive(:changes_will_exceed_size_limit?)
            .with(change_size)
            .and_return(true)

        expect do
          push_access_check
        end.to raise_error(described_class::ForbiddenError, /Your push to this repository would cause it to exceed the size limit/)
      end

      it_behaves_like 'migration bot does not err'
    end

    context 'when GIT_OBJECT_DIRECTORY_RELATIVE env var is set' do
      let(:change_size) { 100 }

      before do
        allow(Gitlab::Git::HookEnv)
          .to receive(:all)
            .with(repository.gl_repository)
            .and_return({ 'GIT_OBJECT_DIRECTORY_RELATIVE' => 'objects' })

        # Stub the object directory size to "simulate" quarantine size
        allow(repository).to receive(:object_directory_size).and_return(change_size)
      end

      it_behaves_like 'a push to repository already over the limit'
      it_behaves_like 'a push to repository below the limit'
      it_behaves_like 'a push to repository to make it over the limit'
    end

    context 'when GIT_OBJECT_DIRECTORY_RELATIVE env var is not set' do
      let(:change_size) { 200 }

      before do
        allow(snippet.repository).to receive(:new_blobs).and_return(
          [double(:blob, size: change_size)]
        )
      end

      it_behaves_like 'a push to repository already over the limit'
      it_behaves_like 'a push to repository below the limit'
      it_behaves_like 'a push to repository to make it over the limit'
    end
  end

  private

  def raise_snippet_not_found
    raise_error(Gitlab::GitAccess::NotFoundError, Gitlab::GitAccess::ERROR_MESSAGES[:snippet_not_found])
  end

  def raise_project_not_found
    raise_error(Gitlab::GitAccess::NotFoundError, Gitlab::GitAccess::ERROR_MESSAGES[:project_not_found])
  end

  def raise_forbidden(message)
    raise_error(Gitlab::GitAccess::ForbiddenError, message)
  end
end
