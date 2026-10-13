# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::States::DestroyService, feature_category: :infrastructure_as_code do
  let(:state) { create(:terraform_state, :with_version, :deletion_in_progress) }

  let(:file) { instance_double(Terraform::StateUploader, relative_path: 'path') }

  before do
    allow_next_found_instance_of(Terraform::StateVersion) do |version|
      allow(version).to receive(:file).and_return(file)
    end
  end

  describe '#execute' do
    subject(:execute) { described_class.new(state).execute }

    context 'when delayed deletion is disabled' do
      before do
        stub_feature_flags(terraform_state_delayed_deletion: false)
      end

      it 'removes version files from object storage, followed by the state record' do
        expect(file).to receive(:remove!).once
        expect(state).to receive(:destroy!)

        execute
      end
    end

    context 'when delayed deletion is enabled' do
      let(:state) { create(:terraform_state, :with_version, :deletion_in_progress) }

      around do |example|
        travel_to(Time.zone.local(2026, 1, 1, 12, 0, 0)) { example.run }
      end

      before do
        stub_feature_flags(terraform_state_delayed_deletion: state.project)
      end

      context 'when the state was deleted within the grace period' do
        before do
          state.update!(deleted_at: Terraform::State::GRACE_PERIOD.ago + 1.second)
        end

        it 'does not remove files or destroy the state record' do
          expect(file).not_to receive(:remove!)
          expect(state).not_to receive(:destroy!)

          execute
        end
      end

      context 'when the state was deleted exactly at the grace-period boundary' do
        before do
          state.update!(deleted_at: Terraform::State::GRACE_PERIOD.ago)
        end

        it 'removes version files and destroys the state record' do
          expect(file).to receive(:remove!).once
          expect(state).to receive(:destroy!)

          execute
        end
      end

      context 'when the state was deleted before the grace period' do
        before do
          state.update!(deleted_at: Terraform::State::GRACE_PERIOD.ago - 1.second)
        end

        it 'removes version files and destroys the state record' do
          expect(file).to receive(:remove!).once
          expect(state).to receive(:destroy!)

          execute
        end
      end
    end

    context 'when the state is not marked for deletion' do
      let(:state) { create(:terraform_state) }

      it 'does not delete the state' do
        expect(state).not_to receive(:destroy!)

        execute
      end
    end
  end
end
