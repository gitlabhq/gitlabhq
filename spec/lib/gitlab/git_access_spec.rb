require 'spec_helper'

describe Gitlab::GitAccess, lib: true do
  let(:access) { Gitlab::GitAccess.new(actor, project, 'web') }
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:actor) { user }

  describe '#check with single protocols allowed' do
    def disable_protocol(protocol)
      settings = ::ApplicationSetting.create_from_defaults
      settings.update_attribute(:enabled_git_access_protocol, protocol)
    end

    context 'ssh disabled' do
      before do
        disable_protocol('ssh')
        @acc = Gitlab::GitAccess.new(actor, project, 'ssh')
      end

      it 'blocks ssh git push' do
        expect(@acc.check('git-receive-pack').allowed?).to be_falsey
      end

      it 'blocks ssh git pull' do
        expect(@acc.check('git-upload-pack').allowed?).to be_falsey
      end
    end

    context 'http disabled' do
      before do
        disable_protocol('http')
        @acc = Gitlab::GitAccess.new(actor, project, 'http')
      end

      it 'blocks http push' do
        expect(@acc.check('git-receive-pack').allowed?).to be_falsey
      end

      it 'blocks http git pull' do
        expect(@acc.check('git-upload-pack').allowed?).to be_falsey
      end
    end
  end

  describe 'download_access_check' do
    subject { access.check('git-upload-pack') }

    describe 'master permissions' do
      before { project.team << [user, :master] }

      context 'pull code' do
        it { expect(subject.allowed?).to be_truthy }
      end
    end

    describe 'guest permissions' do
      before { project.team << [user, :guest] }

      context 'pull code' do
        it { expect(subject.allowed?).to be_falsey }
      end
    end

    describe 'blocked user' do
      before do
        project.team << [user, :master]
        user.block
      end

      context 'pull code' do
        it { expect(subject.allowed?).to be_falsey }
      end
    end

    describe 'without acccess to project' do
      context 'pull code' do
        it { expect(subject.allowed?).to be_falsey }
      end
    end

    describe 'deploy key permissions' do
      let(:key) { create(:deploy_key) }
      let(:actor) { key }

      context 'pull code' do
        context 'when project is authorized' do
          before { key.projects << project }

          it { expect(subject).to be_allowed }
        end

        context 'when unauthorized' do
          context 'from public project' do
            let(:project) { create(:project, :public) }

            it { expect(subject).to be_allowed }
          end

          context 'from internal project' do
            let(:project) { create(:project, :internal) }

            it { expect(subject).not_to be_allowed }
          end

          context 'from private project' do
            let(:project) { create(:project, :internal) }

            it { expect(subject).not_to be_allowed }
          end
        end
      end
    end
  end

  describe 'push_access_check' do
    before { merge_into_protected_branch }
    let(:unprotected_branch) { FFaker::Internet.user_name }

    let(:changes) do
      { push_new_branch: "#{Gitlab::Git::BLANK_SHA} 570e7b2ab refs/heads/wow",
        push_master: '6f6d7e7ed 570e7b2ab refs/heads/master',
        push_protected_branch: '6f6d7e7ed 570e7b2ab refs/heads/feature',
        push_remove_protected_branch: "570e7b2ab #{Gitlab::Git::BLANK_SHA} "\
                                      'refs/heads/feature',
        push_tag: '6f6d7e7ed 570e7b2ab refs/tags/v1.0.0',
        push_new_tag: "#{Gitlab::Git::BLANK_SHA} 570e7b2ab refs/tags/v7.8.9",
        push_all: ['6f6d7e7ed 570e7b2ab refs/heads/master', '6f6d7e7ed 570e7b2ab refs/heads/feature'],
        merge_into_protected_branch: "0b4bc9a #{merge_into_protected_branch} refs/heads/feature" }
    end

    def stub_git_hooks
      # Running the `pre-receive` hook is expensive, and not necessary for this test.
      allow_any_instance_of(GitHooksService).to receive(:execute).and_yield
    end

    def merge_into_protected_branch
      @protected_branch_merge_commit ||= begin
        stub_git_hooks
        project.repository.add_branch(user, unprotected_branch, 'feature')
        target_branch = project.repository.lookup('feature')
        source_branch = project.repository.commit_file(user, FFaker::InternetSE.login_user_name, FFaker::HipsterIpsum.paragraph, FFaker::HipsterIpsum.sentence, unprotected_branch, false)
        rugged = project.repository.rugged
        author = { email: "email@example.com", time: Time.now, name: "Example Git User" }

        merge_index = rugged.merge_commits(target_branch, source_branch)
        Rugged::Commit.create(rugged, author: author, committer: author, message: "commit message", parents: [target_branch, source_branch], tree: merge_index.write_tree(rugged))
      end
    end

    def self.run_permission_checks(permissions_matrix)
      permissions_matrix.keys.each do |role|
        describe "#{role} access" do
          before { project.team << [user, role] }

          permissions_matrix[role].each do |action, allowed|
            context action do
              subject { access.push_access_check(changes[action]) }

              it { expect(subject.allowed?).to allowed ? be_truthy : be_falsey }
            end
          end
        end
      end
    end

    permissions_matrix = {
      master: {
        push_new_branch: true,
        push_master: true,
        push_protected_branch: true,
        push_remove_protected_branch: false,
        push_tag: true,
        push_new_tag: true,
        push_all: true,
        merge_into_protected_branch: true
      },

      developer: {
        push_new_branch: true,
        push_master: true,
        push_protected_branch: false,
        push_remove_protected_branch: false,
        push_tag: false,
        push_new_tag: true,
        push_all: false,
        merge_into_protected_branch: false
      },

      reporter: {
        push_new_branch: false,
        push_master: false,
        push_protected_branch: false,
        push_remove_protected_branch: false,
        push_tag: false,
        push_new_tag: false,
        push_all: false,
        merge_into_protected_branch: false
      },

      guest: {
        push_new_branch: false,
        push_master: false,
        push_protected_branch: false,
        push_remove_protected_branch: false,
        push_tag: false,
        push_new_tag: false,
        push_all: false,
        merge_into_protected_branch: false
      }
    }

    [['feature', 'exact'], ['feat*', 'wildcard']].each do |protected_branch_name, protected_branch_type|
      context do
        before { create(:protected_branch, name: protected_branch_name, project: project) }

        run_permission_checks(permissions_matrix)
      end

      context "when 'developers can push' is turned on for the #{protected_branch_type} protected branch" do
        before { create(:protected_branch, name: protected_branch_name, developers_can_push: true, project: project) }

        run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true }))
      end

      context "when 'developers can merge' is turned on for the #{protected_branch_type} protected branch" do
        before { create(:protected_branch, name: protected_branch_name, developers_can_merge: true, project: project) }

        context "when a merge request exists for the given source/target branch" do
          context "when the merge request is in progress" do
            before do
              create(:merge_request, source_project: project, source_branch: unprotected_branch, target_branch: 'feature', state: 'locked', in_progress_merge_commit_sha: merge_into_protected_branch)
            end

            run_permission_checks(permissions_matrix.deep_merge(developer: { merge_into_protected_branch: true }))
          end

          context "when the merge request is not in progress" do
            before do
              create(:merge_request, source_project: project, source_branch: unprotected_branch, target_branch: 'feature', in_progress_merge_commit_sha: nil)
            end

            run_permission_checks(permissions_matrix.deep_merge(developer: { merge_into_protected_branch: false }))
          end
        end

        context "when a merge request does not exist for the given source/target branch" do
          run_permission_checks(permissions_matrix.deep_merge(developer: { merge_into_protected_branch: false }))
        end
      end

      context "when 'developers can merge' and 'developers can push' are turned on for the #{protected_branch_type} protected branch" do
        before { create(:protected_branch, name: protected_branch_name, developers_can_merge: true, developers_can_push: true, project: project) }

        run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true }))
      end
    end

    describe 'deploy key permissions' do
      let(:key) { create(:deploy_key) }
      let(:actor) { key }

      context 'push code' do
        subject { access.check('git-receive-pack') }

        context 'when project is authorized' do
          before { key.projects << project }

          it { expect(subject).not_to be_allowed }
        end

        context 'when unauthorized' do
          context 'to public project' do
            let(:project) { create(:project, :public) }

            it { expect(subject).not_to be_allowed }
          end

          context 'to internal project' do
            let(:project) { create(:project, :internal) }

            it { expect(subject).not_to be_allowed }
          end

          context 'to private project' do
            let(:project) { create(:project, :internal) }

            it { expect(subject).not_to be_allowed }
          end
        end
      end
    end
  end
end
