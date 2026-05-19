# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitions::ArchiveService, feature_category: :ci_scaling do
  let(:service) { described_class.new(current_partition) }

  describe '#execute' do
    subject(:execute) { service.execute }

    context 'when current_partition is nil' do
      let(:current_partition) { nil }

      it 'does nothing' do
        expect(Ci::Partition).not_to receive(:id_before)

        execute
      end
    end

    context 'when there are no active partitions' do
      before_all do
        create(:ci_partition)
        create(:ci_partition, :archived)
      end

      let_it_be(:current_partition) { create(:ci_partition, :current) }

      it 'does not check current application settings' do
        expect(Gitlab::CurrentSettings).not_to receive(:current_application_settings)

        execute
      end
    end

    context 'when there are active partitions', :freeze_time do
      let_it_be_with_reload(:active_partition) { create(:ci_partition, :active) }
      let_it_be_with_reload(:current_partition) { create(:ci_partition, :current) }

      before do
        stub_application_setting(archive_builds_in_seconds: 1.hour.to_i)
        active_partition.update!(current_until: try(:current_until))
      end

      context 'when current_until is older than the archive threshold' do
        let_it_be(:current_until) { 2.hours.ago }

        it 'transitions the partition to archived' do
          expect { execute }
            .to change { active_partition.reload.status_name }.from(:active).to(:archived)
        end

        context 'when the partition is after current' do
          let_it_be_with_reload(:active_partition_after_current) do
            create(:ci_partition, :active, current_until: current_until)
          end

          it 'only transitions the partition before current to archived' do
            expect { execute }
              .to change { active_partition.reload.status_name }.from(:active).to(:archived)
              .and not_change { active_partition_after_current.reload.status_name }
          end
        end
      end

      context 'when current_until is within the archive threshold' do
        let(:current_until) { 30.minutes.ago }

        it 'does not transition the partition' do
          expect { execute }.not_to change { active_partition.reload.status_name }
        end
      end

      context 'when current_until is nil' do
        let(:current_until) { nil }

        it 'does not transition the partition' do
          expect { execute }.not_to change { active_partition.reload.status_name }
        end
      end

      context 'when archive_builds_older_than is not set' do
        before do
          stub_application_setting(archive_builds_in_seconds: nil)
        end

        it 'does not transition the partition' do
          expect { execute }.not_to change { active_partition.reload.status_name }
        end
      end
    end
  end
end
