# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:graphql rake tasks', :silence_stdout, feature_category: :integrations do
  let(:introspection_output_dir) { Rails.root.join('public/-/graphql') }

  before do
    Rake.application.rake_require 'tasks/gitlab/graphql_introspection'
    stub_warn_user_is_not_gitlab
  end

  describe 'gitlab:graphql:generate_introspection_schema' do
    context 'when introspection query returns errors' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return({
          'errors' => [{ 'message' => 'Test error' }]
        })
      end

      it 'raises SystemExit' do
        expect { run_rake_task('gitlab:graphql:generate_introspection_schema') }.to raise_error(SystemExit)
      end
    end

    context 'when introspection result has no types' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return({
          'data' => { '__schema' => { 'types' => [] } }
        })
      end

      it 'raises SystemExit' do
        expect { run_rake_task('gitlab:graphql:generate_introspection_schema') }.to raise_error(SystemExit)
      end
    end

    context 'when an exception occurs' do
      before do
        allow(GitlabSchema).to receive(:execute).and_raise(StandardError, 'Test exception')
      end

      it 'raises SystemExit' do
        expect { run_rake_task('gitlab:graphql:generate_introspection_schema') }.to raise_error(SystemExit)
      end
    end

    context 'when introspection query succeeds' do
      let(:valid_result) do
        {
          'data' => {
            '__schema' => {
              'types' => [
                { 'name' => 'Query' },
                { 'name' => 'Mutation' }
              ]
            }
          }
        }
      end

      before do
        allow(GitlabSchema).to receive(:execute).and_return(valid_result)
        allow(FileUtils).to receive(:mkdir_p)
        allow(File).to receive(:write)
      end

      it 'writes the introspection result to file' do
        run_rake_task('gitlab:graphql:generate_introspection_schema')

        expect(File).to have_received(:write).with(
          File.join(introspection_output_dir, 'introspection_result.json'),
          "#{Gitlab::Json.pretty_generate(valid_result)}\n"
        )
      end

      it 'prints success message' do
        expect { run_rake_task('gitlab:graphql:generate_introspection_schema') }
          .to output(/GraphQL introspection schema generated successfully \(2 types\)/).to_stdout
      end
    end
  end

  describe 'gitlab:graphql:generate_introspection_schema_no_deprecated' do
    context 'when introspection query returns errors' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return({
          'errors' => [{ 'message' => 'Test error' }]
        })
      end

      it 'raises SystemExit' do
        expect do
          run_rake_task('gitlab:graphql:generate_introspection_schema_no_deprecated')
        end.to raise_error(SystemExit)
      end
    end

    context 'when introspection result has no types' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return({
          'data' => { '__schema' => { 'types' => [] } }
        })
      end

      it 'raises SystemExit' do
        expect do
          run_rake_task('gitlab:graphql:generate_introspection_schema_no_deprecated')
        end.to raise_error(SystemExit)
      end
    end

    context 'when an exception occurs' do
      before do
        allow(GitlabSchema).to receive(:execute).and_raise(StandardError, 'Test exception')
      end

      it 'raises SystemExit' do
        expect do
          run_rake_task('gitlab:graphql:generate_introspection_schema_no_deprecated')
        end.to raise_error(SystemExit)
      end
    end

    context 'when introspection query succeeds' do
      let(:valid_result) do
        {
          'data' => {
            '__schema' => {
              'types' => [
                { 'name' => 'Query' }
              ]
            }
          }
        }
      end

      before do
        allow(GitlabSchema).to receive(:execute).and_return(valid_result)
        allow(FileUtils).to receive(:mkdir_p)
        allow(File).to receive(:write)
      end

      it 'writes the introspection result without deprecated fields to file' do
        run_rake_task('gitlab:graphql:generate_introspection_schema_no_deprecated')

        expect(File).to have_received(:write).with(
          File.join(introspection_output_dir, 'introspection_result_no_deprecated.json'),
          "#{Gitlab::Json.pretty_generate(valid_result)}\n"
        )
      end

      it 'prints success message' do
        expect { run_rake_task('gitlab:graphql:generate_introspection_schema_no_deprecated') }
          .to output(
            /GraphQL introspection schema generated successfully without deprecated fields \(1 types\)/
          ).to_stdout
      end
    end
  end

  describe 'gitlab:graphql:generate_all_introspection_schemas' do
    context 'when both schemas generate successfully' do
      let(:valid_result) do
        {
          'data' => {
            '__schema' => {
              'types' => [{ 'name' => 'Query' }]
            }
          }
        }
      end

      before do
        allow(GitlabSchema).to receive(:execute).and_return(valid_result)
        allow(FileUtils).to receive(:mkdir_p)
        allow(File).to receive(:write)
      end

      it 'prints success message' do
        expect { run_rake_task('gitlab:graphql:generate_all_introspection_schemas') }
          .to output(/✅ All GraphQL introspection schemas generated successfully/).to_stdout
      end
    end
  end

  describe 'gitlab:graphql:check_introspection_sync' do
    let(:valid_result) do
      {
        'data' => {
          '__schema' => {
            'types' => [{ 'name' => 'Query' }]
          }
        }
      }
    end

    context 'when GraphQL execution returns errors' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return({
          'errors' => [{ 'message' => 'Test error' }]
        })
      end

      it 'raises SystemExit' do
        expect { run_rake_task('gitlab:graphql:check_introspection_sync') }.to raise_error(SystemExit)
      end
    end

    context 'when an exception occurs during execution' do
      before do
        allow(GitlabSchema).to receive(:execute).and_raise(StandardError, 'Test exception')
      end

      it 'raises SystemExit' do
        expect { run_rake_task('gitlab:graphql:check_introspection_sync') }.to raise_error(SystemExit)
      end
    end

    context 'when schema files do not exist' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return(valid_result)
        allow(File).to receive(:exist?).and_return(false)
      end

      it 'raises SystemExit' do
        expect { run_rake_task('gitlab:graphql:check_introspection_sync') }.to raise_error(SystemExit)
      end
    end

    context 'when schema files are out of date' do
      let(:old_result) do
        {
          'data' => {
            '__schema' => {
              'types' => [{ 'name' => 'OldQuery' }]
            }
          }
        }
      end

      before do
        allow(GitlabSchema).to receive(:execute).and_return(valid_result)
        allow(File).to receive_messages(exist?: true, read: "#{Gitlab::Json.pretty_generate(old_result)}\n")
      end

      it 'raises SystemExit' do
        expect { run_rake_task('gitlab:graphql:check_introspection_sync') }.to raise_error(SystemExit)
      end

      it 'prints out of date schema paths' do
        expect do
          run_rake_task('gitlab:graphql:check_introspection_sync')
        rescue SystemExit, SystemExitDetected
          # Expected - task calls abort
        end.to output(%r{public/-/graphql/introspection_result.json}).to_stdout
      end
    end

    context 'when schema files are up to date' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return(valid_result)
        allow(File).to receive_messages(exist?: true, read: "#{Gitlab::Json.pretty_generate(valid_result)}\n")
      end

      it 'does not raise an error' do
        expect { run_rake_task('gitlab:graphql:check_introspection_sync') }.not_to raise_error
      end

      it 'prints success message' do
        expect { run_rake_task('gitlab:graphql:check_introspection_sync') }
          .to output(/✅ All GraphQL introspection schemas are up to date/).to_stdout
      end
    end
  end

  describe 'gitlab:graphql:clean_introspection' do
    context 'when introspection directory exists' do
      before do
        allow(Dir).to receive(:exist?).with(introspection_output_dir).and_return(true)
        allow(Dir).to receive(:glob).with(File.join(introspection_output_dir, '*'))
          .and_return(['file1.json', 'file2.json'])
        allow(FileUtils).to receive(:rm_rf)
      end

      it 'removes files from the directory' do
        run_rake_task('gitlab:graphql:clean_introspection')

        expect(FileUtils).to have_received(:rm_rf).with(['file1.json', 'file2.json'])
      end
    end

    context 'when introspection directory does not exist' do
      before do
        allow(Dir).to receive(:exist?).with(introspection_output_dir).and_return(false)
      end

      it 'does not attempt to remove files' do
        expect(Dir).not_to receive(:glob).with(File.join(introspection_output_dir, '*'))

        run_rake_task('gitlab:graphql:clean_introspection')
      end
    end
  end

  # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- Necessary here.
  describe 'simulate_saas task' do
    context 'when not on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'overrides Gitlab.com? to return true' do
        run_rake_task('gitlab:simulate_saas')

        expect(Gitlab.com?).to be true
      end
    end

    context 'when already on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'does not modify Gitlab.com?' do
        run_rake_task('gitlab:simulate_saas')

        expect(Gitlab.com?).to be true
      end
    end
  end
  # rubocop:enable Gitlab/AvoidGitlabInstanceChecks
end
