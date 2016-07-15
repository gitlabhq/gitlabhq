require 'spec_helper'

describe CreateCommitBuildsService, services: true do
  let(:service) { CreateCommitBuildsService.new }
  let(:project) { FactoryGirl.create(:empty_project) }
  let(:user) { create(:user) }

  before do
    stub_ci_pipeline_to_return_yaml_file
  end

  describe '#execute' do
    context 'valid params' do
      let(:pipeline) do
        service.execute(project, user,
                        ref: 'refs/heads/master',
                        before: '00000000',
                        after: '31das312',
                        commits: [{ message: "Message" }]
                       )
      end

      it { expect(pipeline).to be_kind_of(Ci::Pipeline) }
      it { expect(pipeline).to be_valid }
      it { expect(pipeline).to be_persisted }
      it { expect(pipeline).to eq(project.pipelines.last) }
      it { expect(pipeline).to have_attributes(user: user) }
      it { expect(pipeline.builds.first).to be_kind_of(Ci::Build) }
    end

    context "skip tag if there is no build for it" do
      it "creates commit if there is appropriate job" do
        result = service.execute(project, user,
                                 ref: 'refs/tags/0_1',
                                 before: '00000000',
                                 after: '31das312',
                                 commits: [{ message: "Message" }]
                                )
        expect(result).to be_persisted
      end

      it "creates commit if there is no appropriate job but deploy job has right ref setting" do
        config = YAML.dump({ deploy: { script: "ls", only: ["0_1"] } })
        stub_ci_pipeline_yaml_file(config)

        result = service.execute(project, user,
                                 ref: 'refs/heads/0_1',
                                 before: '00000000',
                                 after: '31das312',
                                 commits: [{ message: "Message" }]
                                )
        expect(result).to be_persisted
      end
    end

    it 'skips creating pipeline for refs without .gitlab-ci.yml' do
      stub_ci_pipeline_yaml_file(nil)
      result = service.execute(project, user,
                               ref: 'refs/heads/0_1',
                               before: '00000000',
                               after: '31das312',
                               commits: [{ message: 'Message' }]
                              )
      expect(result).to be_falsey
      expect(Ci::Pipeline.count).to eq(0)
    end

    it 'fails commits if yaml is invalid' do
      message = 'message'
      allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { message }
      stub_ci_pipeline_yaml_file('invalid: file: file')
      commits = [{ message: message }]
      pipeline = service.execute(project, user,
                                 ref: 'refs/tags/0_1',
                                 before: '00000000',
                                 after: '31das312',
                                 commits: commits
                                )
      expect(pipeline).to be_persisted
      expect(pipeline.builds.any?).to be false
      expect(pipeline.status).to eq('failed')
      expect(pipeline.yaml_errors).not_to be_nil
    end

    context 'when commit contains a [ci skip] directive' do
      let(:message) { "some message[ci skip]" }
      let(:messageFlip) { "some message[skip ci]" }
      let(:capMessage) { "some message[CI SKIP]" }
      let(:capMessageFlip) { "some message[SKIP CI]" }

      before do
        allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { message }
      end

      it "skips builds creation if there is [ci skip] tag in commit message" do
        commits = [{ message: message }]
        pipeline = service.execute(project, user,
                                   ref: 'refs/tags/0_1',
                                   before: '00000000',
                                   after: '31das312',
                                   commits: commits
                                  )

        expect(pipeline).to be_persisted
        expect(pipeline.builds.any?).to be false
        expect(pipeline.status).to eq("skipped")
      end

      it "skips builds creation if there is [skip ci] tag in commit message" do
        commits = [{ message: messageFlip }]
        pipeline = service.execute(project, user,
                                   ref: 'refs/tags/0_1',
                                   before: '00000000',
                                   after: '31das312',
                                   commits: commits
                                  )

        expect(pipeline).to be_persisted
        expect(pipeline.builds.any?).to be false
        expect(pipeline.status).to eq("skipped")
      end

      it "skips builds creation if there is [CI SKIP] tag in commit message" do
        commits = [{ message: capMessage }]
        pipeline = service.execute(project, user,
                                   ref: 'refs/tags/0_1',
                                   before: '00000000',
                                   after: '31das312',
                                   commits: commits
                                  )

        expect(pipeline).to be_persisted
        expect(pipeline.builds.any?).to be false
        expect(pipeline.status).to eq("skipped")
      end

      it "skips builds creation if there is [SKIP CI] tag in commit message" do
        commits = [{ message: capMessageFlip }]
        pipeline = service.execute(project, user,
                                   ref: 'refs/tags/0_1',
                                   before: '00000000',
                                   after: '31das312',
                                   commits: commits
                                  )

        expect(pipeline).to be_persisted
        expect(pipeline.builds.any?).to be false
        expect(pipeline.status).to eq("skipped")
      end

      it "does not skips builds creation if there is no [ci skip] or [skip ci] tag in commit message" do
        allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { "some message" }

        commits = [{ message: "some message" }]
        pipeline = service.execute(project, user,
                                   ref: 'refs/tags/0_1',
                                   before: '00000000',
                                   after: '31das312',
                                   commits: commits
                                  )

        expect(pipeline).to be_persisted
        expect(pipeline.builds.first.name).to eq("staging")
      end

      it "skips builds creation if there is [ci skip] tag in commit message and yaml is invalid" do
        stub_ci_pipeline_yaml_file('invalid: file: fiile')
        commits = [{ message: message }]
        pipeline = service.execute(project, user,
                                   ref: 'refs/tags/0_1',
                                   before: '00000000',
                                   after: '31das312',
                                   commits: commits
                                  )
        expect(pipeline).to be_persisted
        expect(pipeline.builds.any?).to be false
        expect(pipeline.status).to eq("skipped")
        expect(pipeline.yaml_errors).to be_nil
      end
    end

    it "skips build creation if there are already builds" do
      allow_any_instance_of(Ci::Pipeline).to receive(:ci_yaml_file) { gitlab_ci_yaml }

      commits = [{ message: "message" }]
      pipeline = service.execute(project, user,
                                 ref: 'refs/heads/master',
                                 before: '00000000',
                                 after: '31das312',
                                 commits: commits
                                )
      expect(pipeline).to be_persisted
      expect(pipeline.builds.count(:all)).to eq(2)

      pipeline = service.execute(project, user,
                                 ref: 'refs/heads/master',
                                 before: '00000000',
                                 after: '31das312',
                                 commits: commits
                                )
      expect(pipeline).to be_persisted
      expect(pipeline.builds.count(:all)).to eq(2)
    end

    it "creates commit with failed status if yaml is invalid" do
      stub_ci_pipeline_yaml_file('invalid: file')

      commits = [{ message: "some message" }]

      pipeline = service.execute(project, user,
                                 ref: 'refs/tags/0_1',
                                 before: '00000000',
                                 after: '31das312',
                                 commits: commits
                                )

      expect(pipeline).to be_persisted
      expect(pipeline.status).to eq("failed")
      expect(pipeline.builds.any?).to be false
    end

    context 'when there are no jobs for this pipeline' do
      before do
        config = YAML.dump({ test: { script: 'ls', only: ['feature'] } })
        stub_ci_pipeline_yaml_file(config)
      end

      it 'does not create a new pipeline' do
        result = service.execute(project, user,
                                 ref: 'refs/heads/master',
                                 before: '00000000',
                                 after: '31das312',
                                 commits: [{ message: 'some msg' }])

        expect(result).to be_falsey
        expect(Ci::Build.all).to be_empty
        expect(Ci::Pipeline.count).to eq(0)
      end
    end
  end
end
