# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DeletedObject, :aggregate_failures, feature_category: :job_artifacts do
  describe 'attributes' do
    it { is_expected.to respond_to(:file) }
    it { is_expected.to respond_to(:store_dir) }
    it { is_expected.to respond_to(:file_store) }
    it { is_expected.to respond_to(:pick_up_at) }
  end

  describe '.bulk_import' do
    context 'with data' do
      let!(:artifact) { create(:ci_job_artifact, :archive, :expired) }

      it 'imports data' do
        expect { described_class.bulk_import(Ci::JobArtifact.all) }.to change { described_class.count }.by(1)

        deleted_artifact = described_class.first

        expect(deleted_artifact.file_store).to eq(artifact.file_store)
        expect(deleted_artifact.store_dir).to eq(artifact.file.store_dir.to_s)
        expect(deleted_artifact.file_identifier).to eq(artifact.file_identifier)
        expect(deleted_artifact.pick_up_at).to be_like_time(artifact.expire_at)
        expect(deleted_artifact.project_id).to eq(artifact.project_id)
      end
    end

    context 'with invalid data' do
      let!(:artifact) { create(:ci_job_artifact) }

      it 'does not import anything' do
        expect(artifact.file_identifier).to be_nil

        expect { described_class.bulk_import([artifact]) }
          .not_to change { described_class.count }
      end
    end

    context 'with empty data' do
      it 'returns successfully' do
        expect { described_class.bulk_import([]) }
          .not_to change { described_class.count }
      end
    end
  end

  context 'ActiveRecord scopes' do
    let_it_be(:not_ready) { create(:ci_deleted_object, pick_up_at: 1.day.from_now) }
    let_it_be(:ready) { create(:ci_deleted_object, pick_up_at: 1.day.ago) }

    describe '.ready_for_destruction' do
      it 'returns objects that are ready' do
        result = described_class.ready_for_destruction(2)

        expect(result).to contain_exactly(ready)
      end
    end

    describe '.lock_for_destruction' do
      subject(:result) { described_class.lock_for_destruction(10) }

      it 'returns objects that are ready' do
        expect(result).to contain_exactly(ready)
      end

      it 'selects only the id' do
        expect(result.select_values).to contain_exactly(:id)
      end

      it 'orders by pick_up_at' do
        expect(result.order_values.map(&:to_sql))
          .to contain_exactly("\"ci_deleted_objects\".\"pick_up_at\" ASC")
      end

      it 'applies limit' do
        expect(result.limit_value).to eq(10)
      end

      it 'uses select for update' do
        expect(result.locked?).to eq('FOR UPDATE SKIP LOCKED')
      end
    end
  end

  describe '#delete_file_from_storage' do
    let(:object) { build(:ci_deleted_object) }

    it 'does not raise errors' do
      expect(object.file).to receive(:remove!).and_raise(StandardError)

      expect(object.delete_file_from_storage).to be_falsy
    end
  end
end
