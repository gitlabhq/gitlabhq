# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Mapper::Verifier, feature_category: :pipeline_composition do
  include RepoHelpers
  include StubRequests

  let_it_be(:project) { create(:project, :small_repo) }
  let_it_be(:user) { project.owner }

  let(:context) do
    Gitlab::Ci::Config::External::Context.new(project: project, user: user, sha: project.commit.id)
  end

  let(:remote_url) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }

  let(:project_files) do
    {
      'myfolder/file1.yml' => <<~YAML,
        my_build:
          script: echo Hello World
      YAML
      'myfolder/file2.yml' => <<~YAML,
        my_test:
          script: echo Hello World
      YAML
      'myfolder/file3.yml' => <<~YAML,
        my_deploy:
          script: echo Hello World
      YAML
      'nested_configs.yml' => <<~YAML
        include:
          - local: myfolder/file1.yml
          - local: myfolder/file2.yml
          - remote: #{remote_url}
      YAML
    }
  end

  around do |example|
    create_and_delete_files(project, project_files) do
      example.run
    end
  end

  before do
    stub_full_request(remote_url).to_return(
      body: <<~YAML
      remote_test:
        script: echo Hello World
      YAML
    )
  end

  subject(:verifier) { described_class.new(context) }

  describe '#process' do
    subject(:process) { verifier.process(files) }

    context 'when files are local' do
      let(:files) do
        [
          Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file1.yml' }, context),
          Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file2.yml' }, context),
          Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file3.yml' }, context)
        ]
      end

      it 'returns an array of file objects' do
        expect(process.map(&:location)).to contain_exactly(
          'myfolder/file1.yml', 'myfolder/file2.yml', 'myfolder/file3.yml'
        )
      end

      it 'adds files to the expandset' do
        expect { process }.to change { context.expandset.count }.by(3)
      end

      it 'calls Gitaly only once for all files', :request_store do
        # 1 for project.commit.id, 1 for the files
        expect { process }.to change { Gitlab::GitalyClient.get_request_count }.by(2)
      end
    end

    context 'when files are project files' do
      let_it_be(:included_project1) { create(:project, :small_repo, namespace: project.namespace, creator: user) }
      let_it_be(:included_project2) { create(:project, :small_repo, namespace: project.namespace, creator: user) }

      let(:files) do
        [
          Gitlab::Ci::Config::External::File::Project.new(
            { file: 'myfolder/file1.yml', project: included_project1.full_path }, context
          ),
          Gitlab::Ci::Config::External::File::Project.new(
            { file: 'myfolder/file2.yml', project: included_project1.full_path }, context
          ),
          Gitlab::Ci::Config::External::File::Project.new(
            { file: 'myfolder/file3.yml', project: included_project1.full_path, ref: 'master' }, context
          ),
          Gitlab::Ci::Config::External::File::Project.new(
            { file: 'myfolder/file1.yml', project: included_project2.full_path }, context
          ),
          Gitlab::Ci::Config::External::File::Project.new(
            { file: 'myfolder/file2.yml', project: included_project2.full_path }, context
          )
        ]
      end

      around do |example|
        create_and_delete_files(included_project1, project_files) do
          create_and_delete_files(included_project2, project_files) do
            example.run
          end
        end
      end

      it 'returns an array of valid file objects' do
        expect(process.map(&:location)).to contain_exactly(
          'myfolder/file1.yml', 'myfolder/file2.yml', 'myfolder/file3.yml', 'myfolder/file1.yml', 'myfolder/file2.yml'
        )

        expect(process.all?(&:valid?)).to be_truthy
      end

      it 'adds files to the expandset' do
        expect { process }.to change { context.expandset.count }.by(5)
      end

      it 'calls Gitaly only once for all files', :request_store do
        files # calling this to load project creations and the `project.commit.id` call

        # 3 for the sha check, 2 for the files in batch
        expect { process }.to change { Gitlab::GitalyClient.get_request_count }.by(5)
      end

      it 'queries with batch', :use_sql_query_cache do
        files # calling this to load project creations and the `project.commit.id` call

        queries = ActiveRecord::QueryRecorder.new(skip_cached: false) { process }
        projects_queries = queries.occurrences_starting_with('SELECT "projects"')
        access_check_queries = queries.occurrences_starting_with('SELECT MAX("project_authorizations"."access_level")')

        # We could not reduce the number of projects queries because we need to call project for
        # the `can_access_local_content?` and `sha` BatchLoaders.
        expect(projects_queries.values.sum).to eq(2)
        expect(access_check_queries.values.sum).to eq(2)
      end

      context 'when a project is missing' do
        let(:files) do
          [
            Gitlab::Ci::Config::External::File::Project.new(
              { file: 'myfolder/file1.yml', project: included_project1.full_path }, context
            ),
            Gitlab::Ci::Config::External::File::Project.new(
              { file: 'myfolder/file2.yml', project: 'invalid-project' }, context
            )
          ]
        end

        it 'returns an array of file objects' do
          expect(process.map(&:location)).to contain_exactly(
            'myfolder/file1.yml', 'myfolder/file2.yml'
          )

          expect(process.all?(&:valid?)).to be_falsey
        end
      end
    end

    context 'when a file includes other files' do
      let(:files) do
        [
          Gitlab::Ci::Config::External::File::Local.new({ local: 'nested_configs.yml' }, context)
        ]
      end

      it 'returns an array of file objects with combined hash' do
        expect(process.map(&:to_hash)).to contain_exactly(
          { my_build: { script: 'echo Hello World' },
            my_test: { script: 'echo Hello World' },
            remote_test: { script: 'echo Hello World' } }
        )
      end
    end

    context 'when there is an invalid file' do
      let(:files) do
        [
          Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/invalid.yml' }, context)
        ]
      end

      it 'adds an error to the file' do
        expect(process.first.errors).to include("Local file `myfolder/invalid.yml` does not exist!")
      end
    end

    describe 'max includes detection' do
      shared_examples 'verifies max includes' do
        context 'when total file count is equal to max_includes' do
          before do
            allow(context).to receive(:max_includes).and_return(expected_total_file_count)
          end

          it 'adds the expected number of files to expandset' do
            expect { process }.not_to raise_error
            expect(context.expandset.count).to eq(expected_total_file_count)
          end
        end

        context 'when total file count exceeds max_includes' do
          before do
            allow(context).to receive(:max_includes).and_return(expected_total_file_count - 1)
          end

          it 'raises error' do
            expect { process }.to raise_error(expected_error_class)
          end
        end
      end

      context 'when files are nested' do
        let(:files) do
          [
            Gitlab::Ci::Config::External::File::Local.new({ local: 'nested_configs.yml' }, context)
          ]
        end

        let(:expected_total_file_count) { 4 } # Includes nested_configs.yml + 3 nested files
        let(:expected_error_class) { Gitlab::Ci::Config::External::Processor::IncludeError }

        it_behaves_like 'verifies max includes'

        context 'when duplicate files are included' do
          let(:expected_total_file_count) { 8 } # 2 x (Includes nested_configs.yml + 3 nested files)
          let(:files) do
            [
              Gitlab::Ci::Config::External::File::Local.new({ local: 'nested_configs.yml' }, context),
              Gitlab::Ci::Config::External::File::Local.new({ local: 'nested_configs.yml' }, context)
            ]
          end

          it_behaves_like 'verifies max includes'
        end
      end

      context 'when files are not nested' do
        let(:files) do
          [
            Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file1.yml' }, context),
            Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file2.yml' }, context)
          ]
        end

        let(:expected_total_file_count) { files.count }
        let(:expected_error_class) { Gitlab::Ci::Config::External::Mapper::TooManyIncludesError }

        it_behaves_like 'verifies max includes'

        context 'when duplicate files are included' do
          let(:files) do
            [
              Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file1.yml' }, context),
              Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file2.yml' }, context),
              Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file2.yml' }, context)
            ]
          end

          let(:expected_total_file_count) { files.count }

          it_behaves_like 'verifies max includes'
        end
      end

      context 'when there is a circular include' do
        let(:project_files) do
          {
            'myfolder/file1.yml' => <<~YAML
              include: myfolder/file1.yml
            YAML
          }
        end

        let(:files) do
          [
            Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file1.yml' }, context)
          ]
        end

        before do
          allow(context).to receive(:max_includes).and_return(10)
        end

        it 'raises error' do
          expect { process }.to raise_error(Gitlab::Ci::Config::External::Processor::IncludeError)
        end
      end

      context 'when a file is an internal include' do
        let(:project_files) do
          {
            'myfolder/file1.yml' => <<~YAML,
              my_build:
                script: echo Hello World
            YAML
            '.internal-include.yml' => <<~YAML
              include:
                - local: myfolder/file1.yml
            YAML
          }
        end

        let(:files) do
          [
            Gitlab::Ci::Config::External::File::Local.new({ local: '.internal-include.yml' }, context)
          ]
        end

        let(:total_file_count) { 2 } # Includes .internal-include.yml + myfolder/file1.yml
        let(:pipeline_config) { instance_double(Gitlab::Ci::ProjectConfig) }

        let(:context) do
          Gitlab::Ci::Config::External::Context.new(
            project: project,
            user: user,
            sha: project.commit.id,
            pipeline_config: pipeline_config
          )
        end

        before do
          allow(pipeline_config).to receive(:internal_include_prepended?).and_return(true)
          allow(context).to receive(:max_includes).and_return(1)
        end

        context 'when total file count excluding internal include is equal to max_includes' do
          it 'does not add the internal include to expandset' do
            expect { process }.not_to raise_error
            expect(context.expandset.count).to eq(total_file_count - 1)
            expect(context.expandset.first.location).to eq('myfolder/file1.yml')
          end
        end

        context 'when total file count excluding internal include exceeds max_includes' do
          let(:project_files) do
            {
              'myfolder/file1.yml' => <<~YAML,
                my_build:
                  script: echo Hello World
              YAML
              '.internal-include.yml' => <<~YAML
                include:
                  - local: myfolder/file1.yml
                  - local: myfolder/file1.yml
              YAML
            }
          end

          it 'raises error' do
            expect { process }.to raise_error(Gitlab::Ci::Config::External::Processor::IncludeError)
          end
        end
      end
    end

    describe '#verify_max_total_pipeline_size' do
      let(:files) do
        [
          Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file1.yml' }, context),
          Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file2.yml' }, context)
        ]
      end

      let(:project_files) do
        {
          'myfolder/file1.yml' => <<~YAML,
            build:
              script: echo Hello World
          YAML
          'myfolder/file2.yml' => <<~YAML
            include:
              - local: myfolder/file1.yml
            build:
              script: echo Hello from the other file
          YAML
        }
      end

      context 'when pipeline tree size is within the limit' do
        before do
          stub_application_setting(ci_max_total_yaml_size_bytes: 10000)
        end

        it 'passes the verification' do
          expect(process.all?(&:valid?)).to be_truthy
        end
      end

      context 'when pipeline tree size is larger then the limit' do
        before do
          stub_application_setting(ci_max_total_yaml_size_bytes: 50)
        end

        let(:expected_error_class) { Gitlab::Ci::Config::External::Mapper::TooMuchDataInPipelineTreeError }

        it 'raises a limit error' do
          expect { process }.to raise_error(expected_error_class)
        end
      end
    end
  end
end
