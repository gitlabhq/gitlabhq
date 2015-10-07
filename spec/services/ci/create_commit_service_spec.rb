require 'spec_helper'

module Ci
  describe CreateCommitService do
    let(:service) { CreateCommitService.new }
    let(:project) { FactoryGirl.create(:ci_project) }
    let(:user) { nil }

    before do
      stub_ci_commit_to_return_yaml_file
    end

    describe :execute do
      context 'valid params' do
        let(:commit) do
          service.execute(project, user,
            ref: 'refs/heads/master',
            before: '00000000',
            after: '31das312',
            commits: [ { message: "Message" } ]
          )
        end

        it { expect(commit).to be_kind_of(Commit) }
        it { expect(commit).to be_valid }
        it { expect(commit).to be_persisted }
        it { expect(commit).to eq(project.commits.last) }
        it { expect(commit.builds.first).to be_kind_of(Build) }
      end

      context "skip tag if there is no build for it" do
        it "creates commit if there is appropriate job" do
          result = service.execute(project, user,
            ref: 'refs/tags/0_1',
            before: '00000000',
            after: '31das312',
            commits: [ { message: "Message" } ]
          )
          expect(result).to be_persisted
        end

        it "creates commit if there is no appropriate job but deploy job has right ref setting" do
          config = YAML.dump({ deploy: { deploy: "ls", only: ["0_1"] } })
          stub_ci_commit_yaml_file(config)

          result = service.execute(project, user,
            ref: 'refs/heads/0_1',
            before: '00000000',
            after: '31das312',
            commits: [ { message: "Message" } ]
          )
          expect(result).to be_persisted
        end
      end

      it 'fails commits without .gitlab-ci.yml' do
        stub_ci_commit_yaml_file(nil)
        result = service.execute(project, user,
                                 ref: 'refs/heads/0_1',
                                 before: '00000000',
                                 after: '31das312',
                                 commits: [ { message: 'Message' } ]
        )
        expect(result).to be_persisted
        expect(result.builds.any?).to be_falsey
        expect(result.status).to eq('failed')
      end

      describe :ci_skip? do
        let(:message) { "some message[ci skip]" }

        before do
          allow_any_instance_of(Ci::Commit).to receive(:git_commit_message) { message }
        end

        it "skips builds creation if there is [ci skip] tag in commit message" do
          commits = [{ message: message }]
          commit = service.execute(project, user,
            ref: 'refs/tags/0_1',
            before: '00000000',
            after: '31das312',
            commits: commits
          )
          expect(commit.builds.any?).to be false
          expect(commit.status).to eq("skipped")
        end

        it "does not skips builds creation if there is no [ci skip] tag in commit message" do
          allow_any_instance_of(Ci::Commit).to receive(:git_commit_message) { "some message" }

          commits = [{ message: "some message" }]
          commit = service.execute(project, user,
            ref: 'refs/tags/0_1',
            before: '00000000',
            after: '31das312',
            commits: commits
          )

          expect(commit.builds.first.name).to eq("staging")
        end

        it "skips builds creation if there is [ci skip] tag in commit message and yaml is invalid" do
          stub_ci_commit_yaml_file('invalid: file')
          commits = [{ message: message }]
          commit = service.execute(project, user,
                                   ref: 'refs/tags/0_1',
                                   before: '00000000',
                                   after: '31das312',
                                   commits: commits
          )
          expect(commit.builds.any?).to be false
          expect(commit.status).to eq("skipped")
        end
      end

      it "skips build creation if there are already builds" do
        allow_any_instance_of(Ci::Commit).to receive(:ci_yaml_file) { gitlab_ci_yaml }

        commits = [{ message: "message" }]
        commit = service.execute(project, user,
          ref: 'refs/heads/master',
          before: '00000000',
          after: '31das312',
          commits: commits
        )
        expect(commit.builds.count(:all)).to  eq(2)

        commit = service.execute(project, user,
          ref: 'refs/heads/master',
          before: '00000000',
          after: '31das312',
          commits: commits
        )
        expect(commit.builds.count(:all)).to eq(2)
      end

      it "creates commit with failed status if yaml is invalid" do
        stub_ci_commit_yaml_file('invalid: file')

        commits = [{ message: "some message" }]

        commit = service.execute(project, user,
                                 ref: 'refs/tags/0_1',
                                 before: '00000000',
                                 after: '31das312',
                                 commits: commits
        )

        expect(commit.status).to eq("failed")
        expect(commit.builds.any?).to be false
      end
    end
  end
end
