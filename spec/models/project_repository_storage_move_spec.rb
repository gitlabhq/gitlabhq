# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectRepositoryStorageMove, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_presence_of(:source_storage_name) }
    it { is_expected.to validate_presence_of(:destination_storage_name) }

    context 'source_storage_name inclusion' do
      subject { build(:project_repository_storage_move, source_storage_name: 'missing') }

      it "does not allow repository storages that don't match a label in the configuration" do
        expect(subject).not_to be_valid
        expect(subject.errors[:source_storage_name].first).to match(/is not included in the list/)
      end
    end

    context 'destination_storage_name inclusion' do
      subject { build(:project_repository_storage_move, destination_storage_name: 'missing') }

      it "does not allow repository storages that don't match a label in the configuration" do
        expect(subject).not_to be_valid
        expect(subject.errors[:destination_storage_name].first).to match(/is not included in the list/)
      end
    end
  end

  describe 'state transitions' do
    using RSpec::Parameterized::TableSyntax

    context 'when in the default state' do
      subject(:storage_move) { create(:project_repository_storage_move, project: project, destination_storage_name: 'test_second_storage') }

      let(:project) { create(:project) }

      before do
        stub_storage_settings('test_second_storage' => { 'path' => 'tmp/tests/extra_storage' })
      end

      context 'and transits to scheduled' do
        it 'triggers ProjectUpdateRepositoryStorageWorker' do
          expect(ProjectUpdateRepositoryStorageWorker).to receive(:perform_async).with(project.id, 'test_second_storage', storage_move.id)

          storage_move.schedule!
        end
      end

      context 'and transits to started' do
        it 'does not allow the transition' do
          expect { storage_move.start! }
            .to raise_error(StateMachines::InvalidTransition)
        end
      end
    end
  end
end
