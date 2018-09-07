require 'fast_spec_helper'

require_dependency 'active_model'

describe Gitlab::Ci::Config do
  let(:project) { create(:project, :repository) }
  let(:config) do
    described_class.new(gitlab_ci_yml, { project: project, branch_name: 'testing' })
  end

  context 'when config is valid' do
    let(:gitlab_ci_yml) do
      <<-EOS
        image: ruby:2.2

        rspec:
          script:
            - gem install rspec
            - rspec
      EOS
    end

    describe '#to_hash' do
      it 'returns hash created from string' do
        hash = {
          image: 'ruby:2.2',
          rspec: {
            script: ['gem install rspec',
                     'rspec']
          }
        }

        expect(config.to_hash).to eq hash
      end

      describe '#valid?' do
        it 'is valid' do
          expect(config).to be_valid
        end

        it 'has no errors' do
          expect(config.errors).to be_empty
        end
      end
    end
  end

  context 'when using extendable hash' do
    let(:yml) do
      <<-EOS
        image: ruby:2.2

        rspec:
          script: rspec

        test:
          extends: rspec
          image: ruby:alpine
      EOS
    end

    it 'correctly extends the hash' do
      hash = {
        image: 'ruby:2.2',
        rspec: { script: 'rspec' },
        test: {
          extends: 'rspec',
          image: 'ruby:alpine',
          script: 'rspec'
        }
      }

      expect(config).to be_valid
      expect(config.to_hash).to eq hash
    end
  end

  context 'when config is invalid' do
    context 'when yml is incorrect' do
      let(:yml) { '// invalid' }

      describe '.new' do
        it 'raises error' do
          expect { config }.to raise_error(
            described_class::ConfigError,
            /Invalid configuration format/
          )
        end
      end
    end

    context 'when config logic is incorrect' do
      let(:yml) { 'before_script: "ls"' }

      describe '#valid?' do
        it 'is not valid' do
          expect(config).not_to be_valid
        end

        it 'has errors' do
          expect(config.errors).not_to be_empty
        end
      end

      describe '#errors' do
        it 'returns an array of strings' do
          expect(config.errors).to all(be_an_instance_of(String))
        end
      end
    end

    context 'when invalid extended hash has been provided' do
      let(:yml) do
        <<-EOS
          test:
            extends: test
            script: rspec
        EOS
      end

      it 'raises an error' do
        expect { config }.to raise_error(
          described_class::ConfigError, /circular dependency detected/
        )
      end
    end
  end

  context "when gitlab_ci_yml has valid 'include' defined" do
    let(:http_file_content) do
      <<~HEREDOC
      variables:
        AUTO_DEVOPS_DOMAIN: domain.example.com
        POSTGRES_USER: user
        POSTGRES_PASSWORD: testing-password
        POSTGRES_ENABLED: "true"
        POSTGRES_DB: $CI_ENVIRONMENT_SLUG
      HEREDOC
    end
    let(:local_file_content) {  File.read("#{Rails.root}/spec/ee/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml") }
    let(:yml) do
      <<-EOS
        include:
          - /spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml
          - https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml

        image: ruby:2.2
      EOS
    end

    before do
      allow_any_instance_of(::Gitlab::Ci::External::File::Local).to receive(:commit).and_return('12345')
      allow_any_instance_of(::Gitlab::Ci::External::File::Local).to receive(:local_file_content).and_return(local_file_content)
      allow(HTTParty).to receive(:get).and_return(http_file_content)
    end

    it 'should return a composed hash' do
      before_script_values = [
        "apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs", "ruby -v",
        "which ruby",
        "gem install bundler --no-ri --no-rdoc",
        "bundle install --jobs $(nproc)  \"${FLAGS[@]}\""
      ]
      variables = {
        AUTO_DEVOPS_DOMAIN: "domain.example.com",
        POSTGRES_USER: "user",
        POSTGRES_PASSWORD: "testing-password",
        POSTGRES_ENABLED: "true",
        POSTGRES_DB: "$CI_ENVIRONMENT_SLUG"
      }
      composed_hash = {
        before_script: before_script_values,
        image: "ruby:2.2",
        rspec: { script: ["bundle exec rspec"] },
        variables: variables
      }

      expect(config.to_hash).to eq(composed_hash)
    end
  end

  context "when gitlab_ci.yml has invalid 'include' defined"  do
    let(:gitlab_ci_yml) do
      <<-EOS
      include: invalid
      EOS
    end

    it 'raises error YamlProcessor ValidationError' do
      expect { config }.to raise_error(
        ::Gitlab::Ci::YamlProcessor::ValidationError,
        "External file: 'invalid' should be a valid local or remote file"
      )
    end
  end

  context "when both external files and gitlab_ci.yml defined the same key" do
    let(:gitlab_ci_yml) do
      <<~HEREDOC
        include:
          - https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.gitlab_ci_yml

        image: ruby:2.2
      HEREDOC
    end

    let(:http_file_content) do
      <<~HEREDOC
        image: php:5-fpm-alpine
      HEREDOC
    end

    it 'should take precedence' do
      allow(HTTParty).to receive(:get).and_return(http_file_content)
      expect(config.to_hash).to eq({ image: 'ruby:2.2' })
    end
  end
end
