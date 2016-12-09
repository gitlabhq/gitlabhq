require 'spec_helper'
require 'validators/git_environment_variables_validator_spec'

describe Gitlab::Git::RevList, lib: true do
  let(:project) { create(:project) }

  context "validations" do
    it_behaves_like(
      "validated git environment variables",
      ->(env, project) { Gitlab::Git::RevList.new('oldrev', 'newrev', project: project, env: env) }
    )
  end

  context "#execute" do
    let(:env) { { "GIT_OBJECT_DIRECTORY" => project.repository.path_to_repo } }
    let(:rev_list) { Gitlab::Git::RevList.new('oldrev', 'newrev', project: project, env: env) }

    it "calls out to `popen` without environment variables if the record is invalid" do
      allow(rev_list).to receive(:valid?).and_return(false)
      allow(Open3).to receive(:popen3)

      rev_list.execute

      expect(Open3).to have_received(:popen3).with(hash_excluding(env), any_args)
    end

    it "calls out to `popen` with environment variables if the record is valid" do
      allow(rev_list).to receive(:valid?).and_return(true)
      allow(Open3).to receive(:popen3)

      rev_list.execute

      expect(Open3).to have_received(:popen3).with(hash_including(env), any_args)
    end
  end
end
