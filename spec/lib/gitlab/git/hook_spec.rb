require 'spec_helper'
require 'fileutils'

describe Gitlab::Git::Hook, lib: true do
  describe "#trigger" do
    let(:project) { create(:project) }
    let(:user) { create(:user) }

    def create_hook(name)
      FileUtils.mkdir_p(File.join(project.repository.path, 'hooks'))
      File.open(File.join(project.repository.path, 'hooks', name), 'w', 0755) do |f|
        f.write('exit 0')
      end
    end

    def create_failing_hook(name)
      FileUtils.mkdir_p(File.join(project.repository.path, 'hooks'))
      File.open(File.join(project.repository.path, 'hooks', name), 'w', 0755) do |f|
        f.write(<<-HOOK)
          echo 'regular message from the hook'
          echo 'error message from the hook' 1>&2
          exit 1
        HOOK
      end
    end

    ['pre-receive', 'post-receive', 'update'].each do |hook_name|
      context "when triggering a #{hook_name} hook" do
        context "when the hook is successful" do
          it "returns success with no errors" do
            create_hook(hook_name)
            hook = Gitlab::Git::Hook.new(hook_name, project.repository.path)
            blank = Gitlab::Git::BLANK_SHA
            ref = Gitlab::Git::BRANCH_REF_PREFIX + 'new_branch'

            status, errors = hook.trigger(Gitlab::GlId.gl_id(user), blank, blank, ref)
            expect(status).to be true
            expect(errors).to be_blank
          end
        end

        context "when the hook is unsuccessful" do
          it "returns failure with errors" do
            create_failing_hook(hook_name)
            hook = Gitlab::Git::Hook.new(hook_name, project.repository.path)
            blank = Gitlab::Git::BLANK_SHA
            ref = Gitlab::Git::BRANCH_REF_PREFIX + 'new_branch'

            status, errors = hook.trigger(Gitlab::GlId.gl_id(user), blank, blank, ref)
            expect(status).to be false
            expect(errors).to eq("error message from the hook\n")
          end
        end
      end
    end

    context "when the hook doesn't exist" do
      it "returns success with no errors" do
        hook = Gitlab::Git::Hook.new('unknown_hook', project.repository.path)
        blank = Gitlab::Git::BLANK_SHA
        ref = Gitlab::Git::BRANCH_REF_PREFIX + 'new_branch'

        status, errors = hook.trigger(Gitlab::GlId.gl_id(user), blank, blank, ref)
        expect(status).to be true
        expect(errors).to be_nil
      end
    end
  end
end
