require 'spec_helper'

describe Ci::CreatePipelineService, services: true do
  let(:project) { FactoryGirl.create(:project) }
  let(:user) { create(:admin) }

  before do
    stub_ci_pipeline_to_return_yaml_file
  end

  describe '#execute' do
    def execute(params)
      described_class.new(project, user, params).execute
    end

    context 'valid params' do
      let(:pipeline) do
        execute(ref: 'refs/heads/master',
                before: '00000000',
                after: project.commit.id,
                commits: [{ message: "Message" }])
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
        result = execute(ref: 'refs/heads/master',
                         before: '00000000',
                         after: project.commit.id,
                         commits: [{ message: "Message" }])
        expect(result).to be_persisted
      end

      it "creates commit if there is no appropriate job but deploy job has right ref setting" do
        config = YAML.dump({ deploy: { script: "ls", only: ["master"] } })
        stub_ci_pipeline_yaml_file(config)
        result = execute(ref: 'refs/heads/master',
                         before: '00000000',
                         after: project.commit.id,
                         commits: [{ message: "Message" }])

        expect(result).to be_persisted
      end
    end

    it 'skips creating pipeline for refs without .gitlab-ci.yml' do
      stub_ci_pipeline_yaml_file(nil)
      result = execute(ref: 'refs/heads/master',
                       before: '00000000',
                       after: project.commit.id,
                       commits: [{ message: 'Message' }])

      expect(result).not_to be_persisted
      expect(Ci::Pipeline.count).to eq(0)
    end

    it 'fails commits if yaml is invalid' do
      message = 'message'
      allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { message }
      stub_ci_pipeline_yaml_file('invalid: file: file')
      commits = [{ message: message }]
      pipeline = execute(ref: 'refs/heads/master',
                         before: '00000000',
                         after: project.commit.id,
                         commits: commits)

      expect(pipeline).to be_persisted
      expect(pipeline.builds.any?).to be false
      expect(pipeline.status).to eq('failed')
      expect(pipeline.yaml_errors).not_to be_nil
    end

    context 'when commit contains a [ci skip] directive' do
      let(:message) { "some message[ci skip]" }

      ci_messages = [
        "some message[ci skip]",
        "some message[skip ci]",
        "some message[CI SKIP]",
        "some message[SKIP CI]",
        "some message[ci_skip]",
        "some message[skip_ci]",
        "some message[ci-skip]",
        "some message[skip-ci]"
      ]

      before do
        allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { message }
      end

      ci_messages.each do |ci_message|
        it "skips builds creation if the commit message is #{ci_message}" do
          commits = [{ message: ci_message }]
          pipeline = execute(ref: 'refs/heads/master',
                             before: '00000000',
                             after: project.commit.id,
                             commits: commits)

          expect(pipeline).to be_persisted
          expect(pipeline.builds.any?).to be false
          expect(pipeline.status).to eq("skipped")
        end
      end

      it "does not skips builds creation if there is no [ci skip] or [skip ci] tag in commit message" do
        allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { "some message" }

        commits = [{ message: "some message" }]
        pipeline = execute(ref: 'refs/heads/master',
                           before: '00000000',
                           after: project.commit.id,
                           commits: commits)

        expect(pipeline).to be_persisted
        expect(pipeline.builds.first.name).to eq("rspec")
      end

      it "does not skip builds creation if the commit message is nil" do
        allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { nil }

        commits = [{ message: nil }]
        pipeline = execute(ref: 'refs/heads/master',
                           before: '00000000',
                           after: project.commit.id,
                           commits: commits)

        expect(pipeline).to be_persisted
        expect(pipeline.builds.first.name).to eq("rspec")
      end

      it "fails builds creation if there is [ci skip] tag in commit message and yaml is invalid" do
        stub_ci_pipeline_yaml_file('invalid: file: fiile')
        commits = [{ message: message }]
        pipeline = execute(ref: 'refs/heads/master',
                           before: '00000000',
                           after: project.commit.id,
                           commits: commits)

        expect(pipeline).to be_persisted
        expect(pipeline.builds.any?).to be false
        expect(pipeline.status).to eq("failed")
        expect(pipeline.yaml_errors).not_to be_nil
      end
    end

    it "creates commit with failed status if yaml is invalid" do
      stub_ci_pipeline_yaml_file('invalid: file')
      commits = [{ message: "some message" }]
      pipeline = execute(ref: 'refs/heads/master',
                         before: '00000000',
                         after: project.commit.id,
                         commits: commits)

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
        result = execute(ref: 'refs/heads/master',
                         before: '00000000',
                         after: project.commit.id,
                         commits: [{ message: 'some msg' }])

        expect(result).not_to be_persisted
        expect(Ci::Build.all).to be_empty
        expect(Ci::Pipeline.count).to eq(0)
      end
    end

    context 'with manual actions' do
      before do
        config = YAML.dump({ deploy: { script: 'ls', when: 'manual' } })
        stub_ci_pipeline_yaml_file(config)
      end

      it 'does not create a new pipeline' do
        result = execute(ref: 'refs/heads/master',
                         before: '00000000',
                         after: project.commit.id,
                         commits: [{ message: 'some msg' }])

        expect(result).to be_persisted
        expect(result.manual_actions).not_to be_empty
      end
    end

    context 'with environment' do
      before do
        config = YAML.dump(deploy: { environment: { name: "review/$CI_BUILD_REF_NAME" }, script: 'ls' })
        stub_ci_pipeline_yaml_file(config)
      end

      it 'creates the environment' do
        result = execute(ref: 'refs/heads/master',
                         before: '00000000',
                         after: project.commit.id,
                         commits: [{ message: 'some msg' }])

        expect(result).to be_persisted
        expect(Environment.find_by(name: "review/master")).not_to be_nil
      end
    end
  end
end
