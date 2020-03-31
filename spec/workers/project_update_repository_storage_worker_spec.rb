# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

describe ProjectUpdateRepositoryStorageWorker do
  let(:project) { create(:project, :repository) }

  subject { described_class.new }

  describe "#perform" do
    context 'when source and target repositories are on different filesystems' do
      before do
        allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
        allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('new_storage').and_return(SecureRandom.uuid)
      end

      it "calls the update repository storage service" do
        expect_next_instance_of(Projects::UpdateRepositoryStorageService) do |instance|
          expect(instance).to receive(:execute).with('new_storage')
        end

        subject.perform(project.id, 'new_storage')
      end
    end

    context 'when source and target repositories are on the same filesystems' do
      let(:filesystem_id) { SecureRandom.uuid }

      before do
        allow(Gitlab::GitalyClient).to receive(:filesystem_id).and_return(filesystem_id)
      end

      it 'raises an error' do
        expect_any_instance_of(::Projects::UpdateRepositoryStorageService).not_to receive(:new)

        expect { subject.perform(project.id, 'new_storage') }.to raise_error(ProjectUpdateRepositoryStorageWorker::SameFilesystemError)
      end
    end
  end
end
