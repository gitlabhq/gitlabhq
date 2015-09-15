require 'spec_helper'

module Ci
  describe GitlabCiYamlProcessor do

    describe "#builds_for_ref" do
      let(:type) { 'test' }

      it "returns builds if no branch specified" do
        config = YAML.dump({
          before_script: ["pwd"],
          rspec: { script: "rspec" }
        })

        config_processor = GitlabCiYamlProcessor.new(config)

        expect(config_processor.builds_for_stage_and_ref(type, "master").size).to eq(1)
        expect(config_processor.builds_for_stage_and_ref(type, "master").first).to eq({
          stage: "test",
          except: nil,
          name: :rspec,
          only: nil,
          script: "pwd\nrspec",
          tags: [],
          options: {},
          allow_failure: false
        })
      end

      it "does not return builds if only has another branch" do
        config = YAML.dump({
          before_script: ["pwd"],
          rspec: { script: "rspec", only: ["deploy"] }
        })

        config_processor = GitlabCiYamlProcessor.new(config)

        expect(config_processor.builds_for_stage_and_ref(type, "master").size).to eq(0)
      end

      it "does not return builds if only has regexp with another branch" do
        config = YAML.dump({
          before_script: ["pwd"],
          rspec: { script: "rspec", only: ["/^deploy$/"] }
        })

        config_processor = GitlabCiYamlProcessor.new(config)

        expect(config_processor.builds_for_stage_and_ref(type, "master").size).to eq(0)
      end

      it "returns builds if only has specified this branch" do
        config = YAML.dump({
          before_script: ["pwd"],
          rspec: { script: "rspec", only: ["master"] }
        })

        config_processor = GitlabCiYamlProcessor.new(config)

        expect(config_processor.builds_for_stage_and_ref(type, "master").size).to eq(1)
      end

      it "does not build tags" do
        config = YAML.dump({
          before_script: ["pwd"],
          rspec: { script: "rspec", except: ["tags"] }
        })

        config_processor = GitlabCiYamlProcessor.new(config)

        expect(config_processor.builds_for_stage_and_ref(type, "0-1", true).size).to eq(0)
      end

      it "returns builds if only has a list of branches including specified" do
        config = YAML.dump({
                             before_script: ["pwd"],
                             rspec: { script: "rspec", type: type, only: ["master", "deploy"] }
                           })

        config_processor = GitlabCiYamlProcessor.new(config)

        expect(config_processor.builds_for_stage_and_ref(type, "deploy").size).to eq(1)
      end

      it "returns build only for specified type" do

        config = YAML.dump({
                             before_script: ["pwd"],
                             build: { script: "build", type: "build", only: ["master", "deploy"] },
                             rspec: { script: "rspec", type: type, only: ["master", "deploy"] },
                             staging: { script: "deploy", type: "deploy", only: ["master", "deploy"] },
                             production: { script: "deploy", type: "deploy", only: ["master", "deploy"] },
                           })

        config_processor = GitlabCiYamlProcessor.new(config)

        expect(config_processor.builds_for_stage_and_ref("production", "deploy").size).to eq(0)
        expect(config_processor.builds_for_stage_and_ref(type, "deploy").size).to eq(1)
        expect(config_processor.builds_for_stage_and_ref("deploy", "deploy").size).to eq(2)
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

        config_processor = GitlabCiYamlProcessor.new(config)

        expect(config_processor.builds_for_stage_and_ref("test", "master").size).to eq(1)
        expect(config_processor.builds_for_stage_and_ref("test", "master").first).to eq({
          except: nil,
          stage: "test",
          name: :rspec,
          only: nil,
          script: "pwd\nrspec",
          tags: [],
          options: {
            image: "ruby:2.1",
            services: ["mysql"]
          },
          allow_failure: false
        })
      end

      it "returns image and service when overridden for job" do
        config = YAML.dump({
                             image:         "ruby:2.1",
                             services:      ["mysql"],
                             before_script: ["pwd"],
                             rspec:         { image: "ruby:2.5", services: ["postgresql"], script: "rspec" }
                           })

        config_processor = GitlabCiYamlProcessor.new(config)

        expect(config_processor.builds_for_stage_and_ref("test", "master").size).to eq(1)
        expect(config_processor.builds_for_stage_and_ref("test", "master").first).to eq({
          except: nil,
          stage: "test",
          name: :rspec,
          only: nil,
          script: "pwd\nrspec",
          tags: [],
          options: {
            image: "ruby:2.5",
            services: ["postgresql"]
          },
          allow_failure: false
        })
      end
    end

    describe "Variables" do
      it "returns variables when defined" do
        variables = {
          var1: "value1",
          var2: "value2",
        }
        config = YAML.dump({
                             variables: variables,
                             before_script: ["pwd"],
                             rspec: { script: "rspec" }
                           })

        config_processor = GitlabCiYamlProcessor.new(config)
        expect(config_processor.variables).to eq(variables)
      end
    end

    describe "Error handling" do
      it "indicates that object is invalid" do
        expect{GitlabCiYamlProcessor.new("invalid_yaml\n!ccdvlf%612334@@@@")}.to raise_error(GitlabCiYamlProcessor::ValidationError)
      end

      it "returns errors if tags parameter is invalid" do
        config = YAML.dump({ rspec: { script: "test", tags: "mysql" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: tags parameter should be an array of strings")
      end

      it "returns errors if before_script parameter is invalid" do
        config = YAML.dump({ before_script: "bundle update", rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "before_script should be an array of strings")
      end

      it "returns errors if image parameter is invalid" do
        config = YAML.dump({ image: ["test"], rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "image should be a string")
      end

      it "returns errors if job image parameter is invalid" do
        config = YAML.dump({ rspec: { script: "test", image: ["test"] } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: image should be a string")
      end

      it "returns errors if services parameter is not an array" do
        config = YAML.dump({ services: "test", rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "services should be an array of strings")
      end

      it "returns errors if services parameter is not an array of strings" do
        config = YAML.dump({ services: [10, "test"], rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "services should be an array of strings")
      end

      it "returns errors if job services parameter is not an array" do
        config = YAML.dump({ rspec: { script: "test", services: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: services should be an array of strings")
      end

      it "returns errors if job services parameter is not an array of strings" do
        config = YAML.dump({ rspec: { script: "test", services: [10, "test"] } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: services should be an array of strings")
      end

      it "returns errors if there are unknown parameters" do
        config = YAML.dump({ extra: "bundle update" })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "Unknown parameter: extra")
      end

      it "returns errors if there are unknown parameters that are hashes, but doesn't have a script" do
        config = YAML.dump({ extra: { services: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "Unknown parameter: extra")
      end

      it "returns errors if there is no any jobs defined" do
        config = YAML.dump({ before_script: ["bundle update"] })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "Please define at least one job")
      end

      it "returns errors if job allow_failure parameter is not an boolean" do
        config = YAML.dump({ rspec: { script: "test", allow_failure: "string" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: allow_failure parameter should be an boolean")
      end

      it "returns errors if job stage is not a string" do
        config = YAML.dump({ rspec: { script: "test", type: 1, allow_failure: "string" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: stage parameter should be build, test, deploy")
      end

      it "returns errors if job stage is not a pre-defined stage" do
        config = YAML.dump({ rspec: { script: "test", type: "acceptance", allow_failure: "string" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: stage parameter should be build, test, deploy")
      end

      it "returns errors if job stage is not a defined stage" do
        config = YAML.dump({ types: ["build", "test"], rspec: { script: "test", type: "acceptance", allow_failure: "string" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "rspec job: stage parameter should be build, test")
      end

      it "returns errors if stages is not an array" do
        config = YAML.dump({ types: "test", rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "stages should be an array of strings")
      end

      it "returns errors if stages is not an array of strings" do
        config = YAML.dump({ types: [true, "test"], rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "stages should be an array of strings")
      end

      it "returns errors if variables is not a map" do
        config = YAML.dump({ variables: "test", rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "variables should be a map of key-valued strings")
      end

      it "returns errors if variables is not a map of key-valued strings" do
        config = YAML.dump({ variables: { test: false }, rspec: { script: "test" } })
        expect do
          GitlabCiYamlProcessor.new(config)
        end.to raise_error(GitlabCiYamlProcessor::ValidationError, "variables should be a map of key-valued strings")
      end
    end
  end
end
