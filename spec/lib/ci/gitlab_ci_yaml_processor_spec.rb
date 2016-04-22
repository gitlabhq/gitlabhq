require 'spec_helper'

module Ci
  describe GitlabCiYamlProcessor, lib: true do
    let(:path) { 'path' }

    describe "#builds_for_ref" do
      let(:type) { 'test' }

      it "returns builds if no branch specified" do
        config = YAML.dump({
          before_script: ["pwd"],
          rspec: { script: "rspec" }
        })

        config_processor = GitlabCiYamlProcessor.new(config, path)

        expect(config_processor.builds_for_stage_and_ref(type, "master").size).to eq(1)
        expect(config_processor.builds_for_stage_and_ref(type, "master").first).to eq({
          stage: "test",
          stage_idx: 1,
          except: nil,
          name: :rspec,
          only: nil,
          commands: "pwd\nrspec",
          tag_list: [],
          options: {},
          allow_failure: false,
          when: "on_success"
        })
      end

      describe :only do
        it "does not return builds if only has another branch" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", only: ["deploy"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "master").size).to eq(0)
        end

        it "does not return builds if only has regexp with another branch" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", only: ["/^deploy$/"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "master").size).to eq(0)
        end

        it "returns builds if only has specified this branch" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", only: ["master"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "master").size).to eq(1)
        end

        it "returns builds if only has a list of branches including specified" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: type, only: ["master", "deploy"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "deploy").size).to eq(1)
        end

        it "returns builds if only has a branches keyword specified" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: type, only: ["branches"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "deploy").size).to eq(1)
        end

        it "does not return builds if only has a tags keyword" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: type, only: ["tags"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "deploy").size).to eq(0)
        end

        it "returns builds if only has a triggers keyword specified and a trigger is provided" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: type, only: ["triggers"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "deploy", false, true).size).to eq(1)
        end

        it "does not return builds if only has a triggers keyword specified and no trigger is provided" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: type, only: ["triggers"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "deploy").size).to eq(0)
        end

        it "returns builds if only has current repository path" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: type, only: ["branches@path"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "deploy").size).to eq(1)
        end

        it "does not return builds if only has different repository path" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: type, only: ["branches@fork"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "deploy").size).to eq(0)
        end

        it "returns build only for specified type" do

          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: "test", only: ["master", "deploy"] },
                               staging: { script: "deploy", type: "deploy", only: ["master", "deploy"] },
                               production: { script: "deploy", type: "deploy", only: ["master@path", "deploy"] },
                             })

          config_processor = GitlabCiYamlProcessor.new(config, 'fork')

          expect(config_processor.builds_for_stage_and_ref("deploy", "deploy").size).to eq(2)
          expect(config_processor.builds_for_stage_and_ref("test", "deploy").size).to eq(1)
          expect(config_processor.builds_for_stage_and_ref("deploy", "master").size).to eq(1)
        end
      end

      describe :except do
        it "returns builds if except has another branch" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", except: ["deploy"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "master").size).to eq(1)
        end

        it "returns builds if except has regexp with another branch" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", except: ["/^deploy$/"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "master").size).to eq(1)
        end

        it "does not return builds if except has specified this branch" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", except: ["master"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "master").size).to eq(0)
        end

        it "does not return builds if except has a list of branches including specified" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: type, except: ["master", "deploy"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "deploy").size).to eq(0)
        end

        it "does not return builds if except has a branches keyword specified" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: type, except: ["branches"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "deploy").size).to eq(0)
        end

        it "returns builds if except has a tags keyword" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: type, except: ["tags"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "deploy").size).to eq(1)
        end

        it "does not return builds if except has a triggers keyword specified and a trigger is provided" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: type, except: ["triggers"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "deploy", false, true).size).to eq(0)
        end

        it "returns builds if except has a triggers keyword specified and no trigger is provided" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: type, except: ["triggers"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "deploy").size).to eq(1)
        end

        it "does not return builds if except has current repository path" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: type, except: ["branches@path"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "deploy").size).to eq(0)
        end

        it "returns builds if except has different repository path" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: type, except: ["branches@fork"] }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.builds_for_stage_and_ref(type, "deploy").size).to eq(1)
        end

        it "returns build except specified type" do
          config = YAML.dump({
                               before_script: ["pwd"],
                               rspec: { script: "rspec", type: "test", except: ["master", "deploy", "test@fork"] },
                               staging: { script: "deploy", type: "deploy", except: ["master"] },
                               production: { script: "deploy", type: "deploy", except: ["master@fork"] },
                             })

          config_processor = GitlabCiYamlProcessor.new(config, 'fork')

          expect(config_processor.builds_for_stage_and_ref("deploy", "deploy").size).to eq(2)
          expect(config_processor.builds_for_stage_and_ref("test", "test").size).to eq(0)
          expect(config_processor.builds_for_stage_and_ref("deploy", "master").size).to eq(0)
        end
      end

    end
    
    describe "Scripts handling" do
      let(:config_data) { YAML.dump(config) }
      let(:config_processor) { GitlabCiYamlProcessor.new(config_data, path) }
      
      subject { config_processor.builds_for_stage_and_ref("test", "master").first }
      
      describe "before_script" do
        context "in global context" do
          let(:config) do
            {
              before_script: ["global script"],
              test: { script: ["script"] }
            }
          end
          
          it "return commands with scripts concencaced" do
            expect(subject[:commands]).to eq("global script\nscript")
          end
        end
 
        context "overwritten in local context" do
          let(:config) do
            {
              before_script: ["global script"],
              test: { before_script: ["local script"], script: ["script"] }
            }
          end

          it "return commands with scripts concencaced" do
            expect(subject[:commands]).to eq("local script\nscript")
          end
        end
      end

      describe "script" do
        let(:config) do
          {
            test: { script: ["script"] }
          }
        end

        it "return commands with scripts concencaced" do
          expect(subject[:commands]).to eq("script")
        end
      end

      describe "after_script" do
        context "in global context" do
          let(:config) do
            {
              after_script: ["after_script"],
              test: { script: ["script"] }
            }
          end

          it "return after_script in options" do
            expect(subject[:options][:after_script]).to eq(["after_script"])
          end
        end

        context "overwritten in local context" do
          let(:config) do
            {
              after_script: ["local after_script"],
              test: { after_script: ["local after_script"], script: ["script"] }
            }
          end

          it "return after_script in options" do
            expect(subject[:options][:after_script]).to eq(["local after_script"])
          end
        end
      end
    end

    describe "Image and service handling" do
      it "returns image and service when defined" do
        config = YAML.dump({
                             image: "ruby:2.1",
                             services: ["mysql"],
                             before_script: ["pwd"],
                             rspec: { script: "rspec" }
                           })

        config_processor = GitlabCiYamlProcessor.new(config, path)

        expect(config_processor.builds_for_stage_and_ref("test", "master").size).to eq(1)
        expect(config_processor.builds_for_stage_and_ref("test", "master").first).to eq({
          except: nil,
          stage: "test",
          stage_idx: 1,
          name: :rspec,
          only: nil,
          commands: "pwd\nrspec",
          tag_list: [],
          options: {
            image: "ruby:2.1",
            services: ["mysql"]
          },
          allow_failure: false,
          when: "on_success"
        })
      end

      it "returns image and service when overridden for job" do
        config = YAML.dump({
                             image:         "ruby:2.1",
                             services:      ["mysql"],
                             before_script: ["pwd"],
                             rspec:         { image: "ruby:2.5", services: ["postgresql"], script: "rspec" }
                           })

        config_processor = GitlabCiYamlProcessor.new(config, path)

        expect(config_processor.builds_for_stage_and_ref("test", "master").size).to eq(1)
        expect(config_processor.builds_for_stage_and_ref("test", "master").first).to eq({
          except: nil,
          stage: "test",
          stage_idx: 1,
          name: :rspec,
          only: nil,
          commands: "pwd\nrspec",
          tag_list: [],
          options: {
            image: "ruby:2.5",
            services: ["postgresql"]
          },
          allow_failure: false,
          when: "on_success"
        })
      end
    end

    describe 'Variables' do
      context 'when global variables are defined' do
        it 'returns global variables' do
          variables = {
            VAR1: 'value1',
            VAR2: 'value2',
          }

          config = YAML.dump({
            variables: variables,
            before_script: ['pwd'],
            rspec: { script: 'rspec' }
          })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.global_variables).to eq(variables)
        end
      end

      context 'when job variables are defined' do
        context 'when syntax is correct' do
          it 'returns job variables' do
            variables =  {
              KEY1: 'value1',
              SOME_KEY_2: 'value2'
            }

            config =  YAML.dump(
              { before_script: ['pwd'],
                rspec: {
                  variables: variables,
                  script: 'rspec' }
              })

            config_processor = GitlabCiYamlProcessor.new(config, path)

            expect(config_processor.job_variables(:rspec)).to eq variables
          end
        end

        context 'when syntax is incorrect' do
          it 'raises error' do
            variables = [:KEY1, 'value1', :KEY2, 'value2']

            config =  YAML.dump(
              { before_script: ['pwd'],
                rspec: {
                  variables: variables,
                  script: 'rspec' }
              })

            expect { GitlabCiYamlProcessor.new(config, path) }
              .to raise_error(GitlabCiYamlProcessor::ValidationError,
                               /job: variables should be a map/)
          end
        end
      end

      context 'when job variables are not defined' do
        it 'returns empty array' do
          config = YAML.dump({
            before_script: ['pwd'],
            rspec: { script: 'rspec' }
          })

          config_processor = GitlabCiYamlProcessor.new(config, path)

          expect(config_processor.job_variables(:rspec)).to eq []
        end
      end
    end

    describe "When" do
      %w(on_success on_failure always).each do |when_state|
        it "returns #{when_state} when defined" do
          config = YAML.dump({
                               rspec: { script: "rspec", when: when_state }
                             })

          config_processor = GitlabCiYamlProcessor.new(config, path)
          builds = config_processor.builds_for_stage_and_ref("test", "master")
          expect(builds.size).to eq(1)
          expect(builds.first[:when]).to eq(when_state)
        end
      end
    end

    describe "Caches" do
      it "returns cache when defined globally" do
        config = YAML.dump({
                             cache: { paths: ["logs/", "binaries/"], untracked: true, key: 'key' },
                             rspec: {
                               script: "rspec"
                             }
                           })

        config_processor = GitlabCiYamlProcessor.new(config)

        expect(config_processor.builds_for_stage_and_ref("test", "master").size).to eq(1)
        expect(config_processor.builds_for_stage_and_ref("test", "master").first[:options][:cache]).to eq(
          paths: ["logs/", "binaries/"],
          untracked: true,
          key: 'key',
        )
      end

      it "returns cache when defined in a job" do
        config = YAML.dump({
                             rspec: {
                               cache: { paths: ["logs/", "binaries/"], untracked: true, key: 'key' },
                               script: "rspec"
                             }
                           })

        config_processor = GitlabCiYamlProcessor.new(config)

        expect(config_processor.builds_for_stage_and_ref("test", "master").size).to eq(1)
        expect(config_processor.builds_for_stage_and_ref("test", "master").first[:options][:cache]).to eq(
          paths: ["logs/", "binaries/"],
          untracked: true,
          key: 'key',
        )
      end

      it "overwrite cache when defined for a job and globally" do
        config = YAML.dump({
                             cache: { paths: ["logs/", "binaries/"], untracked: true, key: 'global' },
                             rspec: {
                               script: "rspec",
                               cache: { paths: ["test/"], untracked: false, key: 'local' },
                             }
                           })

        config_processor = GitlabCiYamlProcessor.new(config)

        expect(config_processor.builds_for_stage_and_ref("test", "master").size).to eq(1)
        expect(config_processor.builds_for_stage_and_ref("test", "master").first[:options][:cache]).to eq(
          paths: ["test/"],
          untracked: false,
          key: 'local',
        )
      end
    end

    describe "Artifacts" do
      it "returns artifacts when defined" do
        config = YAML.dump({
                             image:         "ruby:2.1",
                             services:      ["mysql"],
                             before_script: ["pwd"],
                             rspec:         {
                               artifacts: { paths: ["logs/", "binaries/"], untracked: true, name: "custom_name" },
                               script: "rspec"
                             }
                           })

        config_processor = GitlabCiYamlProcessor.new(config)

        expect(config_processor.builds_for_stage_and_ref("test", "master").size).to eq(1)
        expect(config_processor.builds_for_stage_and_ref("test", "master").first).to eq({
          except: nil,
          stage: "test",
          stage_idx: 1,
          name: :rspec,
          only: nil,
          commands: "pwd\nrspec",
          tag_list: [],
          options: {
            image: "ruby:2.1",
            services: ["mysql"],
            artifacts: {
              name: "custom_name",
              paths: ["logs/", "binaries/"],
              untracked: true
            }
          },
          when: "on_success",
          allow_failure: false
        })
      end
    end

    describe "Dependencies" do
      let(:config) do
        {
          build1: { stage: 'build', script: 'test' },
          build2: { stage: 'build', script: 'test' },
          test1: { stage: 'test', script: 'test', dependencies: dependencies },
          test2: { stage: 'test', script: 'test' },
          deploy: { stage: 'test', script: 'test' }
        }
      end

      subject { GitlabCiYamlProcessor.new(YAML.dump(config)) }

      context 'no dependencies' do
        let(:dependencies) { }

        it { expect { subject }.to_not raise_error }
      end

      context 'dependencies to builds' do
        let(:dependencies) { ['build1', 'build2'] }

        it { expect { subject }.to_not raise_error }
      end

      context 'dependencies to builds defined as symbols' do
        let(:dependencies) { [:build1, :build2] }

        it { expect { subject }.to_not raise_error }
      end

      context 'undefined dependency' do
        let(:dependencies) { ['undefined'] }

        it { expect { subject }.to raise_error(GitlabCiYamlProcessor::ValidationError, 'test1 job: undefined dependency: undefined') }
      end

      context 'dependencies to deploy' do
        let(:dependencies) { ['deploy'] }

        it { expect { subject }.to raise_error(GitlabCiYamlProcessor::ValidationError, 'test1 job: dependency deploy is not defined in prior stages') }
      end
    end

    describe "Hidden jobs" do
      let(:config_processor) { GitlabCiYamlProcessor.new(config) }
      subject { config_processor.builds_for_stage_and_ref("test", "master") }

      shared_examples 'hidden_job_handling' do
        it "doesn't create jobs that start with dot" do
          expect(subject.size).to eq(1)
          expect(subject.first).to eq({
            except: nil,
            stage: "test",
            stage_idx: 1,
            name: :normal_job,
            only: nil,
            commands: "test",
            tag_list: [],
            options: {},
            when: "on_success",
            allow_failure: false
          })
        end
      end

      context 'when hidden job have a script definition' do
        let(:config) do
          YAML.dump({
                      '.hidden_job' => { image: 'ruby:2.1', script: 'test' },
                      'normal_job' => { script: 'test' }
                    })
        end

        it_behaves_like 'hidden_job_handling'
      end

      context "when hidden job doesn't have a script definition" do
        let(:config) do
          YAML.dump({
                      '.hidden_job' => { image: 'ruby:2.1' },
                      'normal_job' => { script: 'test' }
                    })
        end

        it_behaves_like 'hidden_job_handling'
      end
    end

    describe "YAML Alias/Anchor" do
      let(:config_processor) { GitlabCiYamlProcessor.new(config) }
      subject { config_processor.builds_for_stage_and_ref("build", "master") }

      shared_examples 'job_templates_handling' do
        it "is correctly supported for jobs" do
          expect(subject.size).to eq(2)
          expect(subject.first).to eq({
            except: nil,
            stage: "build",
            stage_idx: 0,
            name: :job1,
            only: nil,
            commands: "execute-script-for-job",
            tag_list: [],
            options: {},
            when: "on_success",
            allow_failure: false
          })
          expect(subject.second).to eq({
            except: nil,
            stage: "build",
            stage_idx: 0,
            name: :job2,
            only: nil,
            commands: "execute-script-for-job",
            tag_list: [],
            options: {},
            when: "on_success",
            allow_failure: false
          })
        end
      end

      context 'when template is a job' do
        let(:config) do
          <<EOT
job1: &JOBTMPL
  stage: build
  script: execute-script-for-job

job2: *JOBTMPL
EOT
        end

        it_behaves_like 'job_templates_handling'
      end

      context 'when template is a hidden job' do
        let(:config) do
          <<EOT
.template: &JOBTMPL
  stage: build
  script: execute-script-for-job

job1: *JOBTMPL

job2: *JOBTMPL
EOT
        end

        it_behaves_like 'job_templates_handling'
      end

      context 'when job adds its own keys to a template definition' do
        let(:config) do
          <<EOT
.template: &JOBTMPL
  stage: build

job1:
  <<: *JOBTMPL
  script: execute-script-for-job

job2:
  <<: *JOBTMPL
  script: execute-script-for-job
EOT
        end

        it_behaves_like 'job_templates_handling'
      end
    end

    describe "Error handling" do
      it "fails to parse YAML" do
        expect{GitlabCiYamlProcessor.new("invalid: yaml: test")}.to raise_error(Psych::SyntaxError)
      end

      it "indicates that object is invalid" do
        expect{GitlabCiYamlProcessor.new("invalid_yaml")}.to raise_error(GitlabCiYamlProcessor::ValidationError)
      end

      it "returns errors if tags parameter is invalid" do
        config = YAML.dump({ rspec: { script: "test", tags: "mysql" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: tags parameter should be an array of strings")
      end

      it "returns errors if before_script parameter is invalid" do
        config = YAML.dump({ before_script: "bundle update", rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "before_script should be an array of strings")
      end

      it "returns errors if job before_script parameter is not an array of strings" do
        config = YAML.dump({ rspec: { script: "test", before_script: [10, "test"] } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: before_script should be an array of strings")
      end

      it "returns errors if after_script parameter is invalid" do
        config = YAML.dump({ after_script: "bundle update", rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "after_script should be an array of strings")
      end

      it "returns errors if job after_script parameter is not an array of strings" do
        config = YAML.dump({ rspec: { script: "test", after_script: [10, "test"] } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: after_script should be an array of strings")
      end

      it "returns errors if image parameter is invalid" do
        config = YAML.dump({ image: ["test"], rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "image should be a string")
      end

      it "returns errors if job name is blank" do
        config = YAML.dump({ '' => { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "job name should be non-empty string")
      end

      it "returns errors if job name is non-string" do
        config = YAML.dump({ 10 => { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "job name should be non-empty string")
      end

      it "returns errors if job image parameter is invalid" do
        config = YAML.dump({ rspec: { script: "test", image: ["test"] } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: image should be a string")
      end

      it "returns errors if services parameter is not an array" do
        config = YAML.dump({ services: "test", rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "services should be an array of strings")
      end

      it "returns errors if services parameter is not an array of strings" do
        config = YAML.dump({ services: [10, "test"], rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "services should be an array of strings")
      end

      it "returns errors if job services parameter is not an array" do
        config = YAML.dump({ rspec: { script: "test", services: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: services should be an array of strings")
      end

      it "returns errors if job services parameter is not an array of strings" do
        config = YAML.dump({ rspec: { script: "test", services: [10, "test"] } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: services should be an array of strings")
      end

      it "returns errors if there are unknown parameters" do
        config = YAML.dump({ extra: "bundle update" })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "Unknown parameter: extra")
      end

      it "returns errors if there are unknown parameters that are hashes, but doesn't have a script" do
        config = YAML.dump({ extra: { services: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "Unknown parameter: extra")
      end

      it "returns errors if there are no jobs defined" do
        config = YAML.dump({ before_script: ["bundle update"] })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "Please define at least one job")
      end

      it "returns errors if job allow_failure parameter is not an boolean" do
        config = YAML.dump({ rspec: { script: "test", allow_failure: "string" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: allow_failure parameter should be an boolean")
      end

      it "returns errors if job stage is not a string" do
        config = YAML.dump({ rspec: { script: "test", type: 1 } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: stage parameter should be build, test, deploy")
      end

      it "returns errors if job stage is not a pre-defined stage" do
        config = YAML.dump({ rspec: { script: "test", type: "acceptance" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: stage parameter should be build, test, deploy")
      end

      it "returns errors if job stage is not a defined stage" do
        config = YAML.dump({ types: ["build", "test"], rspec: { script: "test", type: "acceptance" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: stage parameter should be build, test")
      end

      it "returns errors if stages is not an array" do
        config = YAML.dump({ types: "test", rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "stages should be an array of strings")
      end

      it "returns errors if stages is not an array of strings" do
        config = YAML.dump({ types: [true, "test"], rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "stages should be an array of strings")
      end

      it "returns errors if variables is not a map" do
        config = YAML.dump({ variables: "test", rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "variables should be a map of key-value strings")
      end

      it "returns errors if variables is not a map of key-value strings" do
        config = YAML.dump({ variables: { test: false }, rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "variables should be a map of key-value strings")
      end

      it "returns errors if job when is not on_success, on_failure or always" do
        config = YAML.dump({ rspec: { script: "test", when: 1 } })
        expect do
          GitlabCiYamlProcessor.new(config, path)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: when parameter should be on_success, on_failure or always")
      end

      it "returns errors if job artifacts:name is not an a string" do
        config = YAML.dump({ types: ["build", "test"], rspec: { script: "test", artifacts: { name: 1 } } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: artifacts:name parameter should be a string")
      end

      it "returns errors if job artifacts:untracked is not an array of strings" do
        config = YAML.dump({ types: ["build", "test"], rspec: { script: "test", artifacts: { untracked: "string" } } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: artifacts:untracked parameter should be an boolean")
      end

      it "returns errors if job artifacts:paths is not an array of strings" do
        config = YAML.dump({ types: ["build", "test"], rspec: { script: "test", artifacts: { paths: "string" } } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: artifacts:paths parameter should be an array of strings")
      end

      it "returns errors if cache:untracked is not an array of strings" do
        config = YAML.dump({ cache: { untracked: "string" }, rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "cache:untracked parameter should be an boolean")
      end

      it "returns errors if cache:paths is not an array of strings" do
        config = YAML.dump({ cache: { paths: "string" }, rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "cache:paths parameter should be an array of strings")
      end

      it "returns errors if cache:key is not a string" do
        config = YAML.dump({ cache: { key: 1 }, rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "cache:key parameter should be a string")
      end

      it "returns errors if job cache:key is not an a string" do
        config = YAML.dump({ types: ["build", "test"], rspec: { script: "test", cache: { key: 1 } } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: cache:key parameter should be a string")
      end

      it "returns errors if job cache:untracked is not an array of strings" do
        config = YAML.dump({ types: ["build", "test"], rspec: { script: "test", cache: { untracked: "string" } } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: cache:untracked parameter should be an boolean")
      end

      it "returns errors if job cache:paths is not an array of strings" do
        config = YAML.dump({ types: ["build", "test"], rspec: { script: "test", cache: { paths: "string" } } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: cache:paths parameter should be an array of strings")
      end

      it "returns errors if job dependencies is not an array of strings" do
        config = YAML.dump({ types: ["build", "test"], rspec: { script: "test", dependencies: "string" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: dependencies parameter should be an array of strings")
      end
    end
  end
end
