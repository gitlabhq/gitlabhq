require 'spec_helper'

describe UnprocessedLfsPush do
  it { is_expected.to belong_to(:project) }

  it { is_expected.to have_db_column(:newrev).of_type(:string).with_options(null: false) }
  it { is_expected.to have_db_column(:ref).of_type(:string).with_options(null: false) }

  describe "#processed!" do
    subject(:unprocessed_lfs_push) { create(:unprocessed_lfs_push) }
    let(:project) { subject.project }

    it 'deletes the record' do
      subject.processed!

      expect(subject).to be_destroyed
    end

    it 'creates a ProcessedLfsRef' do
      expect { subject.processed! }.to change(ProcessedLfsRef, :count).by(1)
    end

    it 'updates an existing ProcessedLfsRef' do
      create(:processed_lfs_ref, project: project, ref: subject.ref)

      expect { subject.processed! }.to change { processed_lfs_push.reload.newrev }
    end

    #TODO: Could create ProcessedLfsRef with sha on force-push or deletion
  end
end
