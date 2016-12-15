require 'spec_helper'

describe Gitlab::Git::RevList, lib: true do
  let(:project) { create(:project) }

  context "validations" do
    context "GIT_OBJECT_DIRECTORY" do
      it "accepts values starting with the project repo path" do
        env = { "GIT_OBJECT_DIRECTORY" => "#{project.repository.path_to_repo}/objects" }
        rev_list = described_class.new('oldrev', 'newrev', project: project, env: env)

        expect(rev_list).to be_valid
      end

      it "rejects values starting not with the project repo path" do
        env = { "GIT_OBJECT_DIRECTORY" => "/some/other/path" }
        rev_list = described_class.new('oldrev', 'newrev', project: project, env: env)

        expect(rev_list).not_to be_valid
      end

      it "rejects values containing the project repo path but not starting with it" do
        env = { "GIT_OBJECT_DIRECTORY" => "/some/other/path/#{project.repository.path_to_repo}" }
        rev_list = described_class.new('oldrev', 'newrev', project: project, env: env)

        expect(rev_list).not_to be_valid
      end
    end

    context "GIT_ALTERNATE_OBJECT_DIRECTORIES" do
      it "accepts values starting with the project repo path" do
        env = { "GIT_ALTERNATE_OBJECT_DIRECTORIES" => project.repository.path_to_repo }
        rev_list = described_class.new('oldrev', 'newrev', project: project, env: env)

        expect(rev_list).to be_valid
      end

      it "rejects values starting not with the project repo path" do
        env = { "GIT_ALTERNATE_OBJECT_DIRECTORIES" => "/some/other/path" }
        rev_list = described_class.new('oldrev', 'newrev', project: project, env: env)

        expect(rev_list).not_to be_valid
      end

      it "rejects values containing the project repo path but not starting with it" do
        env = { "GIT_ALTERNATE_OBJECT_DIRECTORIES" => "/some/other/path/#{project.repository.path_to_repo}" }
        rev_list = described_class.new('oldrev', 'newrev', project: project, env: env)

        expect(rev_list).not_to be_valid
      end
    end
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
