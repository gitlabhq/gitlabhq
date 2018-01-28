require 'spec_helper'
require 'fileutils'

describe Gitlab::Git::Hook do
  before do
    # We need this because in the spec/spec_helper.rb we define it like this:
    # allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return([true, nil])
    allow_any_instance_of(described_class).to receive(:trigger).and_call_original
  end

  describe "#trigger" do
    let(:project) { create(:project, :repository) }
    let(:repository) { project.repository.raw_repository }
    let(:repo_path) { repository.path }
    let(:user) { create(:user) }
    let(:gl_id) { Gitlab::GlId.gl_id(user) }
    let(:gl_username) { user.username }

    def create_hook(name)
      FileUtils.mkdir_p(File.join(repo_path, 'hooks'))
      File.open(File.join(repo_path, 'hooks', name), 'w', 0755) do |f|
        f.write('exit 0')
      end
    end

    def create_failing_hook(name)
      FileUtils.mkdir_p(File.join(repo_path, 'hooks'))
      File.open(File.join(repo_path, 'hooks', name), 'w', 0755) do |f|
        f.write(<<-HOOK)
          echo 'regular message from the hook'
          echo 'error message from the hook' 1>&2
          echo 'error message from the hook line 2' 1>&2
          exit 1
        HOOK
      end
    end

    ['pre-receive', 'post-receive', 'update'].each do |hook_name|
      context "when triggering a #{hook_name} hook" do
        context "when the hook is successful" do
          let(:hook_path) { File.join(repo_path, 'hooks', hook_name) }
          let(:gl_repository) { Gitlab::GlRepository.gl_repository(project, false) }
          let(:env) do
            {
              'GL_ID' => gl_id,
              'GL_USERNAME' => gl_username,
              'PWD' => repo_path,
              'GL_PROTOCOL' => 'web',
              'GL_REPOSITORY' => gl_repository
            }
          end

          it "returns success with no errors" do
            create_hook(hook_name)
            hook = described_class.new(hook_name, repository)
            blank = Gitlab::Git::BLANK_SHA
            ref = Gitlab::Git::BRANCH_REF_PREFIX + 'new_branch'

            if hook_name != 'update'
              expect(Open3).to receive(:popen3)
                .with(env, hook_path, chdir: repo_path).and_call_original
            end

            status, errors = hook.trigger(gl_id, gl_username, blank, blank, ref)
            expect(status).to be true
            expect(errors).to be_blank
          end
        end

        context "when the hook is unsuccessful" do
          it "returns failure with errors" do
            create_failing_hook(hook_name)
            hook = described_class.new(hook_name, repository)
            blank = Gitlab::Git::BLANK_SHA
            ref = Gitlab::Git::BRANCH_REF_PREFIX + 'new_branch'

            status, errors = hook.trigger(gl_id, gl_username, blank, blank, ref)
            expect(status).to be false
            expect(errors).to eq("error message from the hook<br>error message from the hook line 2<br>")
          end
        end
      end
    end

    context "when the hook doesn't exist" do
      it "returns success with no errors" do
        hook = described_class.new('unknown_hook', repository)
        blank = Gitlab::Git::BLANK_SHA
        ref = Gitlab::Git::BRANCH_REF_PREFIX + 'new_branch'

        status, errors = hook.trigger(gl_id, gl_username, blank, blank, ref)
        expect(status).to be true
        expect(errors).to be_nil
      end
    end
  end
end
