require 'spec_helper'

shared_examples_for "validated git environment variables" do |record_fn| 
  subject { GitEnvironmentVariablesValidator.new(attributes: ['env']) }
  let(:project) { create(:project) }

  context "GIT_OBJECT_DIRECTORY" do
    it "accepts values starting with the project repo path" do
      env = { "GIT_OBJECT_DIRECTORY" => "#{project.repository.path_to_repo}/objects" }
      record = record_fn[env, project]

      subject.validate_each(record, 'env', env)

      expect(record).to be_valid, "expected #{project.repository.path_to_repo}"
    end

    it "rejects values starting not with the project repo path" do
      env = { "GIT_OBJECT_DIRECTORY" => "/some/other/path" }
      record = record_fn[env, project]

      subject.validate_each(record, 'env', env)

      expect(record).to be_invalid
    end

    it "rejects values containing the project repo path but not starting with it" do
      env = { "GIT_OBJECT_DIRECTORY" => "/some/other/path/#{project.repository.path_to_repo}" }
      record = record_fn[env, project]

      subject.validate_each(record, 'env', env)

      expect(record).to be_invalid
    end
  end

  context "GIT_ALTERNATE_OBJECT_DIRECTORIES" do
    it "accepts values starting with the project repo path" do
      env = { "GIT_ALTERNATE_OBJECT_DIRECTORIES" => project.repository.path_to_repo }
      record = record_fn[env, project]

      subject.validate_each(record, 'env', env)

      expect(record).to be_valid, "expected #{project.repository.path_to_repo}"
    end

    it "rejects values starting not with the project repo path" do
      env = { "GIT_ALTERNATE_OBJECT_DIRECTORIES" => "/some/other/path" }
      record = record_fn[env, project]

      subject.validate_each(record, 'env', env)

      expect(record).to be_invalid
    end

    it "rejects values containing the project repo path but not starting with it" do
      env = { "GIT_ALTERNATE_OBJECT_DIRECTORIES" => "/some/other/path/#{project.repository.path_to_repo}" }
      record = record_fn[env, project]

      subject.validate_each(record, 'env', env)

      expect(record).to be_invalid
    end
  end
end
