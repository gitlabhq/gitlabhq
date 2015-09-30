require 'spec_helper'

module Ci
  describe CreateCommitService do
    let(:service) { CreateCommitService.new }
    let(:project) { FactoryGirl.create(:ci_project) }

    describe :execute do
      context 'valid params' do
        let(:commit) do
          service.execute(project,
            ref: 'refs/heads/master',
            before: '00000000',
            after: '31das312',
            ci_yaml_file: gitlab_ci_yaml,
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
          result = service.execute(project,
            ref: 'refs/tags/0_1',
            before: '00000000',
            after: '31das312',
            ci_yaml_file: gitlab_ci_yaml,
            commits: [ { message: "Message" } ]
          )
          expect(result).to be_persisted
        end

        it "creates commit if there is no appropriate job but deploy job has right ref setting" do
          config = YAML.dump({ deploy: { deploy: "ls", only: ["0_1"] } })

          result = service.execute(project,
            ref: 'refs/heads/0_1',
            before: '00000000',
            after: '31das312',
            ci_yaml_file: config,
            commits: [ { message: "Message" } ]
          )
          expect(result).to be_persisted
        end
      end

      it 'fails commits without .gitlab-ci.yml' do
        result = service.execute(project,
                                 ref: 'refs/heads/0_1',
                                 before: '00000000',
                                 after: '31das312',
                                 ci_yaml_file: config,
                                 commits: [ { message: 'Message' } ]
        )
        expect(result).to be_persisted
        expect(result.builds.any?).to be_falsey
        expect(result.status).to eq('failed')
      end

      describe :ci_skip? do
        it "skips builds creation if there is [ci skip] tag in commit message" do
          commits = [{ message: "some message[ci skip]" }]
          commit = service.execute(project,
            ref: 'refs/tags/0_1',
            before: '00000000',
            after: '31das312',
            commits: commits,
            ci_yaml_file: gitlab_ci_yaml
          )
          expect(commit.builds.any?).to be false
          expect(commit.status).to eq("skipped")
        end

        it "does not skips builds creation if there is no [ci skip] tag in commit message" do
          commits = [{ message: "some message" }]

          commit = service.execute(project,
            ref: 'refs/tags/0_1',
            before: '00000000',
            after: '31das312',
            commits: commits,
            ci_yaml_file: gitlab_ci_yaml
          )

          expect(commit.builds.first.name).to eq("staging")
        end

        it "skips builds creation if there is [ci skip] tag in commit message and yaml is invalid" do
          commits = [{ message: "some message[ci skip]" }]
          commit = service.execute(project,
                                   ref: 'refs/tags/0_1',
                                   before: '00000000',
                                   after: '31das312',
                                   commits: commits,
                                   ci_yaml_file: "invalid: file"
          )
          expect(commit.builds.any?).to be false
          expect(commit.status).to eq("skipped")
        end
      end

      it "skips build creation if there are already builds" do
        commits = [{ message: "message" }]
        commit = service.execute(project,
          ref: 'refs/heads/master',
          before: '00000000',
          after: '31das312',
          commits: commits,
          ci_yaml_file: gitlab_ci_yaml
        )
        expect(commit.builds.count(:all)).to  eq(2)

        commit = service.execute(project,
          ref: 'refs/heads/master',
          before: '00000000',
          after: '31das312',
          commits: commits,
          ci_yaml_file: gitlab_ci_yaml
        )
        expect(commit.builds.count(:all)).to eq(2)
      end

      it "creates commit with failed status if yaml is invalid" do
        commits = [{ message: "some message" }]

        commit = service.execute(project,
                                 ref: 'refs/tags/0_1',
                                 before: '00000000',
                                 after: '31das312',
                                 commits: commits,
                                 ci_yaml_file: "invalid: file"
        )

        expect(commit.status).to eq("failed")
        expect(commit.builds.any?).to be false
      end
    end
  end
end
