# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:praefect:replicas', :silence_stdout do
  before do
    Rake.application.rake_require 'tasks/gitlab/praefect'
  end

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  describe 'replicas', :praefect do
    context 'when a valid project id is used as the argument' do
      let(:project_arg) { project.id }

      it "calls praefect info service's replicas method" do
        expect_any_instance_of(Gitlab::GitalyClient::PraefectInfoService).to receive(:replicas).and_call_original

        run_rake_task('gitlab:praefect:replicas', project_arg)
      end

      it 'prints out the expected row' do
        row = /#{project.name}\s+\| #{project.repository.checksum}/

        expect { run_rake_task('gitlab:praefect:replicas', project_arg) }.to output(row).to_stdout
      end
    end

    context 'when no project id is provided' do
      it 'prints out the expected row for all projects' do
        # Note: We don't mock Project.find_each here because the rake task environment
        # makes it difficult to mock effectively. Instead, we verify the behavior by
        # checking that the task outputs the expected replica checksums for all projects.
        row = /#{project.name}\s+\| #{project.repository.checksum}/

        expect { run_rake_task('gitlab:praefect:replicas') }.to output(row).to_stdout
      end
    end

    context 'when a non existent project id is used as the argument' do
      let(:project_arg) { '2' }

      it "does not call praefect info service's replicas method" do
        expect_any_instance_of(Gitlab::GitalyClient::PraefectInfoService).not_to receive(:replicas)

        run_rake_task('gitlab:praefect:replicas', project_arg)
      end
    end

    context 'when an invalid project id is used as the argument' do
      let(:project_arg) { 'invalid' }

      it "does not call praefect info service's replicas method" do
        expect_any_instance_of(Gitlab::GitalyClient::PraefectInfoService).not_to receive(:replicas)

        run_rake_task('gitlab:praefect:replicas', project_arg)
      end

      it 'prints a helpful error message' do
        expect { run_rake_task('gitlab:praefect:replicas', project_arg) }
          .to output(/argument must be a valid project_id/).to_stdout
      end
    end

    context 'when replicas throws an exception' do
      before do
        allow_next_instance_of(Gitlab::GitalyClient::PraefectInfoService) do |instance|
          expect(instance).to receive(:replicas).and_raise("error")
        end
      end

      it 'aborts with the correct error message for a specific project' do
        expect { run_rake_task('gitlab:praefect:replicas', project.id) }.to output(/Something went wrong when getting replicas for project #{project.id}\./).to_stdout
      end
    end
  end
end
