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

    context 'when a non existent project id is used as the argument' do
      let(:project_arg) { '2' }

      it "does not call praefect info service's replicas method" do
        expect_any_instance_of(Gitlab::GitalyClient::PraefectInfoService).not_to receive(:replicas)

        run_rake_task('gitlab:praefect:replicas', project_arg)
      end
    end

    context 'when replicas throws an exception' do
      before do
        allow_next_instance_of(Gitlab::GitalyClient::PraefectInfoService) do |instance|
          expect(instance).to receive(:replicas).and_raise("error")
        end
      end

      it 'aborts with the correct error message' do
        expect { run_rake_task('gitlab:praefect:replicas', project.id) }.to output("Something went wrong when getting replicas.\n").to_stdout
      end
    end
  end
end
