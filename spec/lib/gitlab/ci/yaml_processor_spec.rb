require 'spec_helper'

module Gitlab
  module Ci
    describe YamlProcessor do
      subject { described_class.new(config) }

      describe 'our current .gitlab-ci.yml' do
        let(:config) { File.read("#{Rails.root}/.gitlab-ci.yml") }

        it 'is valid' do
          error_message = described_class.validation_message(config)

          expect(error_message).to be_nil
        end
      end

      describe '#build_attributes' do
        subject { described_class.new(config).build_attributes(:rspec) }

        describe 'coverage entry' do
          describe 'code coverage regexp' do
            let(:config) do
              YAML.dump(rspec: { script: 'rspec',
                                 coverage: '/Code coverage: \d+\.\d+/' })
            end

            it 'includes coverage regexp in build attributes' do
              expect(subject)
                .to include(coverage_regex: 'Code coverage: \d+\.\d+')
            end
          end
        end

        describe 'retry entry' do
          context 'when retry count is specified' do
            let(:config) do
              YAML.dump(rspec: { script: 'rspec', retry: 1 })
            end

            it 'includes retry count in build options attribute' do
              expect(subject[:options]).to include(retry: 1)
            end
          end

          context 'when retry count is not specified' do
            let(:config) do
              YAML.dump(rspec: { script: 'rspec' })
            end

            it 'does not persist retry count in the database' do
              expect(subject[:options]).not_to have_key(:retry)
            end
          end
        end

        describe 'allow failure entry' do
          context 'when job is a manual action' do
            context 'when allow_failure is defined' do
              let(:config) do
                YAML.dump(rspec: { script: 'rspec',
                                   when: 'manual',
                                   allow_failure: false })
              end

              it 'is not allowed to fail' do
                expect(subject[:allow_failure]).to be false
              end
            end

            context 'when allow_failure is not defined' do
              let(:config) do
                YAML.dump(rspec: { script: 'rspec',
                                   when: 'manual' })
              end

              it 'is allowed to fail' do
                expect(subject[:allow_failure]).to be true
              end
            end
          end

          context 'when job is not a manual action' do
            context 'when allow_failure is defined' do
              let(:config) do
                YAML.dump(rspec: { script: 'rspec',
                                   allow_failure: false })
              end

              it 'is not allowed to fail' do
                expect(subject[:allow_failure]).to be false
              end
            end

            context 'when allow_failure is not defined' do
              let(:config) do
                YAML.dump(rspec: { script: 'rspec' })
              end

              it 'is not allowed to fail' do
                expect(subject[:allow_failure]).to be false
              end
            end
          end
        end
      end

      describe '#stage_seeds' do
        context 'when no refs policy is specified' do
          let(:config) do
            YAML.dump(production: { stage: 'deploy', script: 'cap prod' },
                      rspec: { stage: 'test', script: 'rspec' },
                      spinach: { stage: 'test', script: 'spinach' })
          end

          let(:pipeline) { create(:ci_empty_pipeline) }

          it 'correctly fabricates a stage seeds object' do
            seeds = subject.stage_seeds(pipeline)

            expect(seeds.size).to eq 2
            expect(seeds.first.attributes[:name]).to eq 'test'
            expect(seeds.second.attributes[:name]).to eq 'deploy'
            expect(seeds.dig(0, 0, :name)).to eq 'rspec'
            expect(seeds.dig(0, 1, :name)).to eq 'spinach'
            expect(seeds.dig(1, 0, :name)).to eq 'production'
          end
        end

        context 'when refs policy is specified' do
          let(:config) do
            YAML.dump(production: { stage: 'deploy', script: 'cap prod', only: ['master'] },
                      spinach: { stage: 'test', script: 'spinach', only: ['tags'] })
          end

          let(:pipeline) do
            create(:ci_empty_pipeline, ref: 'feature', tag: true)
          end

          it 'returns stage seeds only assigned to master to master' do
            seeds = subject.stage_seeds(pipeline)

            expect(seeds.size).to eq 1
            expect(seeds.first.attributes[:name]).to eq 'test'
            expect(seeds.dig(0, 0, :name)).to eq 'spinach'
          end
        end

        context 'when source policy is specified' do
          let(:config) do
            YAML.dump(production: { stage: 'deploy', script: 'cap prod', only: ['triggers'] },
                      spinach: { stage: 'test', script: 'spinach', only: ['schedules'] })
          end

          let(:pipeline) do
            create(:ci_empty_pipeline, source: :schedule)
          end

          it 'returns stage seeds only assigned to schedules' do
            seeds = subject.stage_seeds(pipeline)

            expect(seeds.size).to eq 1
            expect(seeds.first.attributes[:name]).to eq 'test'
            expect(seeds.dig(0, 0, :name)).to eq 'spinach'
          end
        end

        context 'when kubernetes policy is specified' do
          let(:config) do
            YAML.dump(
              spinach: { stage: 'test', script: 'spinach' },
              production: {
                stage: 'deploy',
                script: 'cap',
                only: { kubernetes: 'active' }
              }
            )
          end

          context 'when kubernetes is active' do
            shared_examples 'same behavior between KubernetesService and Platform::Kubernetes' do
              it 'returns seeds for kubernetes dependent job' do
                seeds = subject.stage_seeds(pipeline)

                expect(seeds.size).to eq 2
                expect(seeds.dig(0, 0, :name)).to eq 'spinach'
                expect(seeds.dig(1, 0, :name)).to eq 'production'
              end
            end

            context 'when user configured kubernetes from Integration > Kubernetes' do
              let(:project) { create(:kubernetes_project) }
              let(:pipeline) { create(:ci_empty_pipeline, project: project) }

              it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
            end

            context 'when user configured kubernetes from CI/CD > Clusters' do
              let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
              let(:project) { cluster.project }
              let(:pipeline) { create(:ci_empty_pipeline, project: project) }

              it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
            end
          end

          context 'when kubernetes is not active' do
            it 'does not return seeds for kubernetes dependent job' do
              seeds = subject.stage_seeds(pipeline)

              expect(seeds.size).to eq 1
              expect(seeds.dig(0, 0, :name)).to eq 'spinach'
            end
          end
        end
      end

      describe "#pipeline_stage_builds" do
        let(:type) { 'test' }

        it "returns builds if no branch specified" do
          config = YAML.dump({
            before_script: ["pwd"],
            rspec: { script: "rspec" }
          })

          config_processor = Gitlab::Ci::YamlProcessor.new(config)

          expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "master")).size).to eq(1)
          expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "master")).first).to eq({
            stage: "test",
            stage_idx: 1,
            name: "rspec",
            commands: "pwd\nrspec",
            coverage_regex: nil,
            tag_list: [],
            options: {
              before_script: ["pwd"],
              script: ["rspec"]
            },
            allow_failure: false,
            when: "on_success",
            environment: nil,
            yaml_variables: []
          })
        end

        describe 'only' do
          it "does not return builds if only has another branch" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", only: ["deploy"] }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "master")).size).to eq(0)
          end

          it "does not return builds if only has regexp with another branch" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", only: ["/^deploy$/"] }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "master")).size).to eq(0)
          end

          it "returns builds if only has specified this branch" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", only: ["master"] }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "master")).size).to eq(1)
          end

          it "returns builds if only has a list of branches including specified" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", type: type, only: %w(master deploy) }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "deploy")).size).to eq(1)
          end

          it "returns builds if only has a branches keyword specified" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", type: type, only: ["branches"] }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "deploy")).size).to eq(1)
          end

          it "does not return builds if only has a tags keyword" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", type: type, only: ["tags"] }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "deploy")).size).to eq(0)
          end

          it "returns builds if only has special keywords specified and source matches" do
            possibilities = [{ keyword: 'pushes', source: 'push' },
                             { keyword: 'web', source: 'web' },
                             { keyword: 'triggers', source: 'trigger' },
                             { keyword: 'schedules', source: 'schedule' },
                             { keyword: 'api', source: 'api' },
                             { keyword: 'external', source: 'external' }]

            possibilities.each do |possibility|
              config = YAML.dump({
                                   before_script: ["pwd"],
                                   rspec: { script: "rspec", type: type, only: [possibility[:keyword]] }
                                 })

              config_processor = Gitlab::Ci::YamlProcessor.new(config)

              expect(config_processor.pipeline_stage_builds(type, pipeline(ref: 'deploy', tag: false, source: possibility[:source])).size).to eq(1)
            end
          end

          it "does not return builds if only has special keywords specified and source doesn't match" do
            possibilities = [{ keyword: 'pushes', source: 'web' },
                             { keyword: 'web', source: 'push' },
                             { keyword: 'triggers', source: 'schedule' },
                             { keyword: 'schedules', source: 'external' },
                             { keyword: 'api', source: 'trigger' },
                             { keyword: 'external', source: 'api' }]

            possibilities.each do |possibility|
              config = YAML.dump({
                                   before_script: ["pwd"],
                                   rspec: { script: "rspec", type: type, only: [possibility[:keyword]] }
                                 })

              config_processor = Gitlab::Ci::YamlProcessor.new(config)

              expect(config_processor.pipeline_stage_builds(type, pipeline(ref: 'deploy', tag: false, source: possibility[:source])).size).to eq(0)
            end
          end

          it "returns builds if only has current repository path" do
            seed_pipeline = pipeline(ref: 'deploy')

            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: {
                                   script: "rspec",
                                   type: type,
                                   only: ["branches@#{seed_pipeline.project_full_path}"]
                                 }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, seed_pipeline).size).to eq(1)
          end

          it "does not return builds if only has different repository path" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", type: type, only: ["branches@fork"] }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "deploy")).size).to eq(0)
          end

          it "returns build only for specified type" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", type: "test", only: %w(master deploy) },
                                 staging: { script: "deploy", type: "deploy", only: %w(master deploy) },
                                 production: { script: "deploy", type: "deploy", only: ["master@path", "deploy"] }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds("deploy", pipeline(ref: "deploy")).size).to eq(2)
            expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "deploy")).size).to eq(1)
            expect(config_processor.pipeline_stage_builds("deploy", pipeline(ref: "master")).size).to eq(1)
          end

          context 'for invalid value' do
            let(:config) { { rspec: { script: "rspec", type: "test", only: only } } }
            let(:processor) { Gitlab::Ci::YamlProcessor.new(YAML.dump(config)) }

            context 'when it is integer' do
              let(:only) { 1 }

              it do
                expect { processor }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                                                    'jobs:rspec:only has to be either an array of conditions or a hash')
              end
            end

            context 'when it is an array of integers' do
              let(:only) { [1, 1] }

              it do
                expect { processor }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                                                    'jobs:rspec:only config should be an array of strings or regexps')
              end
            end

            context 'when it is invalid regex' do
              let(:only) { ["/*invalid/"] }

              it do
                expect { processor }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                                                    'jobs:rspec:only config should be an array of strings or regexps')
              end
            end
          end
        end

        describe 'except' do
          it "returns builds if except has another branch" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", except: ["deploy"] }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "master")).size).to eq(1)
          end

          it "returns builds if except has regexp with another branch" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", except: ["/^deploy$/"] }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "master")).size).to eq(1)
          end

          it "does not return builds if except has specified this branch" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", except: ["master"] }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "master")).size).to eq(0)
          end

          it "does not return builds if except has a list of branches including specified" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", type: type, except: %w(master deploy) }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "deploy")).size).to eq(0)
          end

          it "does not return builds if except has a branches keyword specified" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", type: type, except: ["branches"] }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "deploy")).size).to eq(0)
          end

          it "returns builds if except has a tags keyword" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", type: type, except: ["tags"] }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "deploy")).size).to eq(1)
          end

          it "does not return builds if except has special keywords specified and source matches" do
            possibilities = [{ keyword: 'pushes', source: 'push' },
                             { keyword: 'web', source: 'web' },
                             { keyword: 'triggers', source: 'trigger' },
                             { keyword: 'schedules', source: 'schedule' },
                             { keyword: 'api', source: 'api' },
                             { keyword: 'external', source: 'external' }]

            possibilities.each do |possibility|
              config = YAML.dump({
                                   before_script: ["pwd"],
                                   rspec: { script: "rspec", type: type, except: [possibility[:keyword]] }
                                 })

              config_processor = Gitlab::Ci::YamlProcessor.new(config)

              expect(config_processor.pipeline_stage_builds(type, pipeline(ref: 'deploy', tag: false, source: possibility[:source])).size).to eq(0)
            end
          end

          it "returns builds if except has special keywords specified and source doesn't match" do
            possibilities = [{ keyword: 'pushes', source: 'web' },
                             { keyword: 'web', source: 'push' },
                             { keyword: 'triggers', source: 'schedule' },
                             { keyword: 'schedules', source: 'external' },
                             { keyword: 'api', source: 'trigger' },
                             { keyword: 'external', source: 'api' }]

            possibilities.each do |possibility|
              config = YAML.dump({
                                   before_script: ["pwd"],
                                   rspec: { script: "rspec", type: type, except: [possibility[:keyword]] }
                                 })

              config_processor = Gitlab::Ci::YamlProcessor.new(config)

              expect(config_processor.pipeline_stage_builds(type, pipeline(ref: 'deploy', tag: false, source: possibility[:source])).size).to eq(1)
            end
          end

          it "does not return builds if except has current repository path" do
            seed_pipeline = pipeline(ref: 'deploy')

            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: {
                                   script: "rspec",
                                   type: type,
                                   except: ["branches@#{seed_pipeline.project_full_path}"]
                                 }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, seed_pipeline).size).to eq(0)
          end

          it "returns builds if except has different repository path" do
            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", type: type, except: ["branches@fork"] }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds(type, pipeline(ref: "deploy")).size).to eq(1)
          end

          it "returns build except specified type" do
            master_pipeline = pipeline(ref: 'master')
            test_pipeline = pipeline(ref: 'test')
            deploy_pipeline = pipeline(ref: 'deploy')

            config = YAML.dump({
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec", type: "test", except: ["master", "deploy", "test@#{test_pipeline.project_full_path}"] },
                                 staging: { script: "deploy", type: "deploy", except: ["master"] },
                                 production: { script: "deploy", type: "deploy", except: ["master@#{master_pipeline.project_full_path}"] }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds("deploy", deploy_pipeline).size).to eq(2)
            expect(config_processor.pipeline_stage_builds("test", test_pipeline).size).to eq(0)
            expect(config_processor.pipeline_stage_builds("deploy", master_pipeline).size).to eq(0)
          end

          context 'for invalid value' do
            let(:config) { { rspec: { script: "rspec", except: except } } }
            let(:processor) { Gitlab::Ci::YamlProcessor.new(YAML.dump(config)) }

            context 'when it is integer' do
              let(:except) { 1 }

              it do
                expect { processor }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                                                    'jobs:rspec:except has to be either an array of conditions or a hash')
              end
            end

            context 'when it is an array of integers' do
              let(:except) { [1, 1] }

              it do
                expect { processor }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                                                    'jobs:rspec:except config should be an array of strings or regexps')
              end
            end

            context 'when it is invalid regex' do
              let(:except) { ["/*invalid/"] }

              it do
                expect { processor }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                                                    'jobs:rspec:except config should be an array of strings or regexps')
              end
            end
          end
        end
      end

      describe "Scripts handling" do
        let(:config_data) { YAML.dump(config) }
        let(:config_processor) { Gitlab::Ci::YamlProcessor.new(config_data) }

        subject { config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).first }

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
        context "when extended docker configuration is used" do
          it "returns image and service when defined" do
            config = YAML.dump({ image: { name: "ruby:2.1", entrypoint: ["/usr/local/bin/init", "run"] },
                                 services: ["mysql", { name: "docker:dind", alias: "docker",
                                                       entrypoint: ["/usr/local/bin/init", "run"],
                                                       command: ["/usr/local/bin/init", "run"] }],
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec" } })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).size).to eq(1)
            expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).first).to eq({
              stage: "test",
              stage_idx: 1,
              name: "rspec",
              commands: "pwd\nrspec",
              coverage_regex: nil,
              tag_list: [],
              options: {
                before_script: ["pwd"],
                script: ["rspec"],
                image: { name: "ruby:2.1", entrypoint: ["/usr/local/bin/init", "run"] },
                services: [{ name: "mysql" },
                           { name: "docker:dind", alias: "docker", entrypoint: ["/usr/local/bin/init", "run"],
                             command: ["/usr/local/bin/init", "run"] }]
              },
              allow_failure: false,
              when: "on_success",
              environment: nil,
              yaml_variables: []
            })
          end

          it "returns image and service when overridden for job" do
            config = YAML.dump({ image: "ruby:2.1",
                                 services: ["mysql"],
                                 before_script: ["pwd"],
                                 rspec: { image: { name: "ruby:2.5", entrypoint: ["/usr/local/bin/init", "run"] },
                                          services: [{ name: "postgresql", alias: "db-pg",
                                                       entrypoint: ["/usr/local/bin/init", "run"],
                                                       command: ["/usr/local/bin/init", "run"] }, "docker:dind"],
                                          script: "rspec" } })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).size).to eq(1)
            expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).first).to eq({
              stage: "test",
              stage_idx: 1,
              name: "rspec",
              commands: "pwd\nrspec",
              coverage_regex: nil,
              tag_list: [],
              options: {
                before_script: ["pwd"],
                script: ["rspec"],
                image: { name: "ruby:2.5", entrypoint: ["/usr/local/bin/init", "run"] },
                services: [{ name: "postgresql", alias: "db-pg", entrypoint: ["/usr/local/bin/init", "run"],
                             command: ["/usr/local/bin/init", "run"] },
                           { name: "docker:dind" }]
              },
              allow_failure: false,
              when: "on_success",
              environment: nil,
              yaml_variables: []
            })
          end
        end

        context "when etended docker configuration is not used" do
          it "returns image and service when defined" do
            config = YAML.dump({ image: "ruby:2.1",
                                 services: ["mysql", "docker:dind"],
                                 before_script: ["pwd"],
                                 rspec: { script: "rspec" } })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).size).to eq(1)
            expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).first).to eq({
              stage: "test",
              stage_idx: 1,
              name: "rspec",
              commands: "pwd\nrspec",
              coverage_regex: nil,
              tag_list: [],
              options: {
                before_script: ["pwd"],
                script: ["rspec"],
                image: { name: "ruby:2.1" },
                services: [{ name: "mysql" }, { name: "docker:dind" }]
              },
              allow_failure: false,
              when: "on_success",
              environment: nil,
              yaml_variables: []
            })
          end

          it "returns image and service when overridden for job" do
            config = YAML.dump({ image: "ruby:2.1",
                                 services: ["mysql"],
                                 before_script: ["pwd"],
                                 rspec: { image: "ruby:2.5", services: ["postgresql", "docker:dind"], script: "rspec" } })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).size).to eq(1)
            expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).first).to eq({
              stage: "test",
              stage_idx: 1,
              name: "rspec",
              commands: "pwd\nrspec",
              coverage_regex: nil,
              tag_list: [],
              options: {
                before_script: ["pwd"],
                script: ["rspec"],
                image: { name: "ruby:2.5" },
                services: [{ name: "postgresql" }, { name: "docker:dind" }]
              },
              allow_failure: false,
              when: "on_success",
              environment: nil,
              yaml_variables: []
            })
          end
        end
      end

      describe 'Variables' do
        let(:config_processor) { Gitlab::Ci::YamlProcessor.new(YAML.dump(config)) }

        subject { config_processor.builds.first[:yaml_variables] }

        context 'when global variables are defined' do
          let(:variables) do
            { 'VAR1' => 'value1', 'VAR2' => 'value2' }
          end
          let(:config) do
            {
              variables: variables,
              before_script: ['pwd'],
              rspec: { script: 'rspec' }
            }
          end

          it 'returns global variables' do
            expect(subject).to contain_exactly(
              { key: 'VAR1', value: 'value1', public: true },
              { key: 'VAR2', value: 'value2', public: true }
            )
          end
        end

        context 'when job and global variables are defined' do
          let(:global_variables) do
            { 'VAR1' => 'global1', 'VAR3' => 'global3' }
          end
          let(:job_variables) do
            { 'VAR1' => 'value1', 'VAR2' => 'value2' }
          end
          let(:config) do
            {
              before_script: ['pwd'],
              variables: global_variables,
              rspec: { script: 'rspec', variables: job_variables }
            }
          end

          it 'returns all unique variables' do
            expect(subject).to contain_exactly(
              { key: 'VAR3', value: 'global3', public: true },
              { key: 'VAR1', value: 'value1', public: true },
              { key: 'VAR2', value: 'value2', public: true }
            )
          end
        end

        context 'when job variables are defined' do
          let(:config) do
            {
              before_script: ['pwd'],
              rspec: { script: 'rspec', variables: variables }
            }
          end

          context 'when syntax is correct' do
            let(:variables) do
              { 'VAR1' => 'value1', 'VAR2' => 'value2' }
            end

            it 'returns job variables' do
              expect(subject).to contain_exactly(
                { key: 'VAR1', value: 'value1', public: true },
                { key: 'VAR2', value: 'value2', public: true }
              )
            end
          end

          context 'when syntax is incorrect' do
            context 'when variables defined but invalid' do
              let(:variables) do
                %w(VAR1 value1 VAR2 value2)
              end

              it 'raises error' do
                expect { subject }
                  .to raise_error(Gitlab::Ci::YamlProcessor::ValidationError,
                                   /jobs:rspec:variables config should be a hash of key value pairs/)
              end
            end

            context 'when variables key defined but value not specified' do
              let(:variables) do
                nil
              end

              it 'returns empty array' do
                ##
                # When variables config is empty, we assume this is a valid
                # configuration, see issue #18775
                #
                expect(subject).to be_an_instance_of(Array)
                expect(subject).to be_empty
              end
            end
          end
        end

        context 'when job variables are not defined' do
          let(:config) do
            {
              before_script: ['pwd'],
              rspec: { script: 'rspec' }
            }
          end

          it 'returns empty array' do
            expect(subject).to be_an_instance_of(Array)
            expect(subject).to be_empty
          end
        end
      end

      describe "When" do
        %w(on_success on_failure always).each do |when_state|
          it "returns #{when_state} when defined" do
            config = YAML.dump({
                                 rspec: { script: "rspec", when: when_state }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            builds = config_processor.pipeline_stage_builds("test", pipeline(ref: "master"))
            expect(builds.size).to eq(1)
            expect(builds.first[:when]).to eq(when_state)
          end
        end
      end

      describe 'cache' do
        context 'when cache definition has unknown keys' do
          it 'raises relevant validation error' do
            config = YAML.dump(
              { cache: { untracked: true, invalid: 'key' },
                rspec: { script: 'rspec' } })

            expect { Gitlab::Ci::YamlProcessor.new(config) }.to raise_error(
              Gitlab::Ci::YamlProcessor::ValidationError,
              'cache config contains unknown keys: invalid'
            )
          end
        end

        it "returns cache when defined globally" do
          config = YAML.dump({
                               cache: { paths: ["logs/", "binaries/"], untracked: true, key: 'key' },
                               rspec: {
                                 script: "rspec"
                               }
                             })

          config_processor = Gitlab::Ci::YamlProcessor.new(config)

          expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).size).to eq(1)
          expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).first[:options][:cache]).to eq(
            paths: ["logs/", "binaries/"],
            untracked: true,
            key: 'key',
            policy: 'pull-push'
          )
        end

        it "returns cache when defined in a job" do
          config = YAML.dump({
                               rspec: {
                                 cache: { paths: ["logs/", "binaries/"], untracked: true, key: 'key' },
                                 script: "rspec"
                               }
                             })

          config_processor = Gitlab::Ci::YamlProcessor.new(config)

          expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).size).to eq(1)
          expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).first[:options][:cache]).to eq(
            paths: ["logs/", "binaries/"],
            untracked: true,
            key: 'key',
            policy: 'pull-push'
          )
        end

        it "overwrite cache when defined for a job and globally" do
          config = YAML.dump({
                               cache: { paths: ["logs/", "binaries/"], untracked: true, key: 'global' },
                               rspec: {
                                 script: "rspec",
                                 cache: { paths: ["test/"], untracked: false, key: 'local' }
                               }
                             })

          config_processor = Gitlab::Ci::YamlProcessor.new(config)

          expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).size).to eq(1)
          expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).first[:options][:cache]).to eq(
            paths: ["test/"],
            untracked: false,
            key: 'local',
            policy: 'pull-push'
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
                                 artifacts: {
                                   paths: ["logs/", "binaries/"],
                                   untracked: true,
                                   name: "custom_name",
                                   expire_in: "7d"
                                 },
                                 script: "rspec"
                               }
                             })

          config_processor = Gitlab::Ci::YamlProcessor.new(config)

          expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).size).to eq(1)
          expect(config_processor.pipeline_stage_builds("test", pipeline(ref: "master")).first).to eq({
            stage: "test",
            stage_idx: 1,
            name: "rspec",
            commands: "pwd\nrspec",
            coverage_regex: nil,
            tag_list: [],
            options: {
              before_script: ["pwd"],
              script: ["rspec"],
              image: { name: "ruby:2.1" },
              services: [{ name: "mysql" }],
              artifacts: {
                name: "custom_name",
                paths: ["logs/", "binaries/"],
                untracked: true,
                expire_in: "7d"
              }
            },
            when: "on_success",
            allow_failure: false,
            environment: nil,
            yaml_variables: []
          })
        end

        %w[on_success on_failure always].each do |when_state|
          it "returns artifacts for when #{when_state}  defined" do
            config = YAML.dump({
                                 rspec: {
                                   script: "rspec",
                                   artifacts: { paths: ["logs/", "binaries/"], when: when_state }
                                 }
                               })

            config_processor = Gitlab::Ci::YamlProcessor.new(config)

            builds = config_processor.pipeline_stage_builds("test", pipeline(ref: "master"))
            expect(builds.size).to eq(1)
            expect(builds.first[:options][:artifacts][:when]).to eq(when_state)
          end
        end
      end

      describe '#environment' do
        let(:config) do
          {
            deploy_to_production: { stage: 'deploy', script: 'test', environment: environment }
          }
        end

        let(:processor) { Gitlab::Ci::YamlProcessor.new(YAML.dump(config)) }
        let(:builds) { processor.pipeline_stage_builds('deploy', pipeline(ref: 'master')) }

        context 'when a production environment is specified' do
          let(:environment) { 'production' }

          it 'does return production' do
            expect(builds.size).to eq(1)
            expect(builds.first[:environment]).to eq(environment)
            expect(builds.first[:options]).to include(environment: { name: environment, action: "start" })
          end
        end

        context 'when hash is specified' do
          let(:environment) do
            { name: 'production',
              url: 'http://production.gitlab.com' }
          end

          it 'does return production and URL' do
            expect(builds.size).to eq(1)
            expect(builds.first[:environment]).to eq(environment[:name])
            expect(builds.first[:options]).to include(environment: environment)
          end

          context 'the url has a port as variable' do
            let(:environment) do
              { name: 'production',
                url: 'http://production.gitlab.com:$PORT' }
            end

            it 'allows a variable for the port' do
              expect(builds.size).to eq(1)
              expect(builds.first[:environment]).to eq(environment[:name])
              expect(builds.first[:options]).to include(environment: environment)
            end
          end
        end

        context 'when no environment is specified' do
          let(:environment) { nil }

          it 'does return nil environment' do
            expect(builds.size).to eq(1)
            expect(builds.first[:environment]).to be_nil
          end
        end

        context 'is not a string' do
          let(:environment) { 1 }

          it 'raises error' do
            expect { builds }.to raise_error(
              'jobs:deploy_to_production:environment config should be a hash or a string')
          end
        end

        context 'is not a valid string' do
          let(:environment) { 'production:staging' }

          it 'raises error' do
            expect { builds }.to raise_error("jobs:deploy_to_production:environment name #{Gitlab::Regex.environment_name_regex_message}")
          end
        end

        context 'when on_stop is specified' do
          let(:review) { { stage: 'deploy', script: 'test', environment: { name: 'review', on_stop: 'close_review' } } }
          let(:config) { { review: review, close_review: close_review }.compact }

          context 'with matching job' do
            let(:close_review) { { stage: 'deploy', script: 'test', environment: { name: 'review', action: 'stop' } } }

            it 'does return a list of builds' do
              expect(builds.size).to eq(2)
              expect(builds.first[:environment]).to eq('review')
            end
          end

          context 'without matching job' do
            let(:close_review) { nil  }

            it 'raises error' do
              expect { builds }.to raise_error('review job: on_stop job close_review is not defined')
            end
          end

          context 'with close job without environment' do
            let(:close_review) { { stage: 'deploy', script: 'test' } }

            it 'raises error' do
              expect { builds }.to raise_error('review job: on_stop job close_review does not have environment defined')
            end
          end

          context 'with close job for different environment' do
            let(:close_review) { { stage: 'deploy', script: 'test', environment: 'production' } }

            it 'raises error' do
              expect { builds }.to raise_error('review job: on_stop job close_review have different environment name')
            end
          end

          context 'with close job without stop action' do
            let(:close_review) { { stage: 'deploy', script: 'test', environment: { name: 'review' } } }

            it 'raises error' do
              expect { builds }.to raise_error('review job: on_stop job close_review needs to have action stop defined')
            end
          end
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

        subject { Gitlab::Ci::YamlProcessor.new(YAML.dump(config)) }

        context 'no dependencies' do
          let(:dependencies) { }

          it { expect { subject }.not_to raise_error }
        end

        context 'dependencies to builds' do
          let(:dependencies) { %w(build1 build2) }

          it { expect { subject }.not_to raise_error }
        end

        context 'dependencies to builds defined as symbols' do
          let(:dependencies) { [:build1, :build2] }

          it { expect { subject }.not_to raise_error }
        end

        context 'undefined dependency' do
          let(:dependencies) { ['undefined'] }

          it { expect { subject }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, 'test1 job: undefined dependency: undefined') }
        end

        context 'dependencies to deploy' do
          let(:dependencies) { ['deploy'] }

          it { expect { subject }.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, 'test1 job: dependency deploy is not defined in prior stages') }
        end
      end

      describe "Hidden jobs" do
        let(:config_processor) { Gitlab::Ci::YamlProcessor.new(config) }
        subject { config_processor.pipeline_stage_builds("test", pipeline(ref: "master")) }

        shared_examples 'hidden_job_handling' do
          it "doesn't create jobs that start with dot" do
            expect(subject.size).to eq(1)
            expect(subject.first).to eq({
              stage: "test",
              stage_idx: 1,
              name: "normal_job",
              commands: "test",
              coverage_regex: nil,
              tag_list: [],
              options: {
                script: ["test"]
              },
              when: "on_success",
              allow_failure: false,
              environment: nil,
              yaml_variables: []
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
        let(:config_processor) { Gitlab::Ci::YamlProcessor.new(config) }
        subject { config_processor.pipeline_stage_builds("build", pipeline(ref: "master")) }

        shared_examples 'job_templates_handling' do
          it "is correctly supported for jobs" do
            expect(subject.size).to eq(2)
            expect(subject.first).to eq({
              stage: "build",
              stage_idx: 0,
              name: "job1",
              commands: "execute-script-for-job",
              coverage_regex: nil,
              tag_list: [],
              options: {
                script: ["execute-script-for-job"]
              },
              when: "on_success",
              allow_failure: false,
              environment: nil,
              yaml_variables: []
            })
            expect(subject.second).to eq({
              stage: "build",
              stage_idx: 0,
              name: "job2",
              commands: "execute-script-for-job",
              coverage_regex: nil,
              tag_list: [],
              options: {
                script: ["execute-script-for-job"]
              },
              when: "on_success",
              allow_failure: false,
              environment: nil,
              yaml_variables: []
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
          expect do
            Gitlab::Ci::YamlProcessor.new("invalid: yaml: test")
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError)
        end

        it "indicates that object is invalid" do
          expect do
            Gitlab::Ci::YamlProcessor.new("invalid_yaml")
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError)
        end

        it "returns errors if tags parameter is invalid" do
          config = YAML.dump({ rspec: { script: "test", tags: "mysql" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec tags should be an array of strings")
        end

        it "returns errors if before_script parameter is invalid" do
          config = YAML.dump({ before_script: "bundle update", rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "before_script config should be an array of strings")
        end

        it "returns errors if job before_script parameter is not an array of strings" do
          config = YAML.dump({ rspec: { script: "test", before_script: [10, "test"] } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:before_script config should be an array of strings")
        end

        it "returns errors if after_script parameter is invalid" do
          config = YAML.dump({ after_script: "bundle update", rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "after_script config should be an array of strings")
        end

        it "returns errors if job after_script parameter is not an array of strings" do
          config = YAML.dump({ rspec: { script: "test", after_script: [10, "test"] } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:after_script config should be an array of strings")
        end

        it "returns errors if image parameter is invalid" do
          config = YAML.dump({ image: ["test"], rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "image config should be a hash or a string")
        end

        it "returns errors if job name is blank" do
          config = YAML.dump({ '' => { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:job name can't be blank")
        end

        it "returns errors if job name is non-string" do
          config = YAML.dump({ 10 => { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:10 name should be a symbol")
        end

        it "returns errors if job image parameter is invalid" do
          config = YAML.dump({ rspec: { script: "test", image: ["test"] } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:image config should be a hash or a string")
        end

        it "returns errors if services parameter is not an array" do
          config = YAML.dump({ services: "test", rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "services config should be a array")
        end

        it "returns errors if services parameter is not an array of strings" do
          config = YAML.dump({ services: [10, "test"], rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "service config should be a hash or a string")
        end

        it "returns errors if job services parameter is not an array" do
          config = YAML.dump({ rspec: { script: "test", services: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:services config should be a array")
        end

        it "returns errors if job services parameter is not an array of strings" do
          config = YAML.dump({ rspec: { script: "test", services: [10, "test"] } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "service config should be a hash or a string")
        end

        it "returns error if job configuration is invalid" do
          config = YAML.dump({ extra: "bundle update" })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:extra config should be a hash")
        end

        it "returns errors if services configuration is not correct" do
          config = YAML.dump({ extra: { script: 'rspec', services: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:extra:services config should be a array")
        end

        it "returns errors if there are no jobs defined" do
          config = YAML.dump({ before_script: ["bundle update"] })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs config should contain at least one visible job")
        end

        it "returns errors if there are no visible jobs defined" do
          config = YAML.dump({ before_script: ["bundle update"], '.hidden'.to_sym => { script: 'ls' } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs config should contain at least one visible job")
        end

        it "returns errors if job allow_failure parameter is not an boolean" do
          config = YAML.dump({ rspec: { script: "test", allow_failure: "string" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec allow failure should be a boolean value")
        end

        it "returns errors if job stage is not a string" do
          config = YAML.dump({ rspec: { script: "test", type: 1 } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:type config should be a string")
        end

        it "returns errors if job stage is not a pre-defined stage" do
          config = YAML.dump({ rspec: { script: "test", type: "acceptance" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "rspec job: stage parameter should be build, test, deploy")
        end

        it "returns errors if job stage is not a defined stage" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", type: "acceptance" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "rspec job: stage parameter should be build, test")
        end

        it "returns errors if stages is not an array" do
          config = YAML.dump({ stages: "test", rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "stages config should be an array of strings")
        end

        it "returns errors if stages is not an array of strings" do
          config = YAML.dump({ stages: [true, "test"], rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "stages config should be an array of strings")
        end

        it "returns errors if variables is not a map" do
          config = YAML.dump({ variables: "test", rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "variables config should be a hash of key value pairs")
        end

        it "returns errors if variables is not a map of key-value strings" do
          config = YAML.dump({ variables: { test: false }, rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "variables config should be a hash of key value pairs")
        end

        it "returns errors if job when is not on_success, on_failure or always" do
          config = YAML.dump({ rspec: { script: "test", when: 1 } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec when should be on_success, on_failure, always or manual")
        end

        it "returns errors if job artifacts:name is not an a string" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", artifacts: { name: 1 } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:artifacts name should be a string")
        end

        it "returns errors if job artifacts:when is not an a predefined value" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", artifacts: { when: 1 } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:artifacts when should be on_success, on_failure or always")
        end

        it "returns errors if job artifacts:expire_in is not an a string" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", artifacts: { expire_in: 1 } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:artifacts expire in should be a duration")
        end

        it "returns errors if job artifacts:expire_in is not an a valid duration" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", artifacts: { expire_in: "7 elephants" } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:artifacts expire in should be a duration")
        end

        it "returns errors if job artifacts:untracked is not an array of strings" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", artifacts: { untracked: "string" } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:artifacts untracked should be a boolean value")
        end

        it "returns errors if job artifacts:paths is not an array of strings" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", artifacts: { paths: "string" } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:artifacts paths should be an array of strings")
        end

        it "returns errors if cache:untracked is not an array of strings" do
          config = YAML.dump({ cache: { untracked: "string" }, rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "cache:untracked config should be a boolean value")
        end

        it "returns errors if cache:paths is not an array of strings" do
          config = YAML.dump({ cache: { paths: "string" }, rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "cache:paths config should be an array of strings")
        end

        it "returns errors if cache:key is not a string" do
          config = YAML.dump({ cache: { key: 1 }, rspec: { script: "test" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "cache:key config should be a string or symbol")
        end

        it "returns errors if job cache:key is not an a string" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", cache: { key: 1 } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:cache:key config should be a string or symbol")
        end

        it "returns errors if job cache:untracked is not an array of strings" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", cache: { untracked: "string" } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:cache:untracked config should be a boolean value")
        end

        it "returns errors if job cache:paths is not an array of strings" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", cache: { paths: "string" } } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec:cache:paths config should be an array of strings")
        end

        it "returns errors if job dependencies is not an array of strings" do
          config = YAML.dump({ types: %w(build test), rspec: { script: "test", dependencies: "string" } })
          expect do
            Gitlab::Ci::YamlProcessor.new(config)
          end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "jobs:rspec dependencies should be an array of strings")
        end
      end

      describe "Validate configuration templates" do
        templates = Dir.glob("#{Rails.root.join('vendor/gitlab-ci-yml')}/**/*.gitlab-ci.yml")

        templates.each do |file|
          it "does not return errors for #{file}" do
            file = File.read(file)

            expect { Gitlab::Ci::YamlProcessor.new(file) }.not_to raise_error
          end
        end
      end

      describe "#validation_message" do
        subject { Gitlab::Ci::YamlProcessor.validation_message(content) }

        context "when the YAML could not be parsed" do
          let(:content) { YAML.dump("invalid: yaml: test") }

          it { is_expected.to eq "Invalid configuration format" }
        end

        context "when the tags parameter is invalid" do
          let(:content) { YAML.dump({ rspec: { script: "test", tags: "mysql" } }) }

          it { is_expected.to eq "jobs:rspec tags should be an array of strings" }
        end

        context "when YAML content is empty" do
          let(:content) { '' }

          it { is_expected.to eq "Please provide content of .gitlab-ci.yml" }
        end

        context 'when the YAML contains an unknown alias' do
          let(:content) { 'steps: *bad_alias' }

          it { is_expected.to eq "Unknown alias: bad_alias" }
        end

        context "when the YAML is valid" do
          let(:content) { File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml')) }

          it { is_expected.to be_nil }
        end
      end

      def pipeline(**attributes)
        build_stubbed(:ci_empty_pipeline, **attributes)
      end
    end
  end
end
