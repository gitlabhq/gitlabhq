# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LfsFileLock, feature_category: :source_code_management do
  let_it_be(:lfs_file_lock, reload: true) { create(:lfs_file_lock) }

  subject { lfs_file_lock }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:user) }

  it { is_expected.to validate_presence_of(:project_id) }
  it { is_expected.to validate_presence_of(:user_id) }
  it { is_expected.to validate_presence_of(:path) }

  describe '#can_be_unlocked_by?' do
    let(:developer) { create(:user) }
    let(:maintainer) { create(:user) }

    before do
      project = lfs_file_lock.project

      project.add_developer(developer)
      project.add_maintainer(maintainer)
    end

    context "when it's forced" do
      it 'can be unlocked by the author' do
        user = lfs_file_lock.user

        expect(lfs_file_lock.can_be_unlocked_by?(user, true)).to eq(true)
      end

      it 'can be unlocked by a maintainer' do
        expect(lfs_file_lock.can_be_unlocked_by?(maintainer, true)).to eq(true)
      end

      it "can't be unlocked by other user" do
        expect(lfs_file_lock.can_be_unlocked_by?(developer, true)).to eq(false)
      end
    end

    context "when it isn't forced" do
      it 'can be unlocked by the author' do
        user = lfs_file_lock.user

        expect(lfs_file_lock.can_be_unlocked_by?(user)).to eq(true)
      end

      it "can't be unlocked by a maintainer" do
        expect(lfs_file_lock.can_be_unlocked_by?(maintainer)).to eq(false)
      end

      it "can't be unlocked by other user" do
        expect(lfs_file_lock.can_be_unlocked_by?(developer)).to eq(false)
      end
    end
  end

  describe '#for_path!(path)' do
    context 'when the lfs_file_lock exists' do
      it 'returns the lfs file lock' do
        expect(described_class.for_path!(lfs_file_lock.path)).to eq(lfs_file_lock)
      end
    end

    context 'when the path does not exist' do
      it 'raises an error' do
        expect { described_class.for_path!('not_a_real_path.rb') }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
