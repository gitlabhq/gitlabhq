require 'rails_helper'

describe CustomEmoji, type: :model do
  subject { create(:custom_emoji) }

  it { is_expected.to belong_to(:namespace) }
  it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  it { is_expected.to have_db_column(:file) }
  it { is_expected.to validate_length_of(:name).is_at_most(36) }
  it { is_expected.to validate_presence_of(:name) }

  describe 'exclusion of duplicated emoji' do
    it 'disallows emoji already in the Unicode spec' do
      new_emoji = build(:custom_emoji, name: Gitlab::Emoji.emojis_names.sample)

      expect(new_emoji).not_to be_valid
    end

    it 'disallows duplicate custom emoji names' do
      ## Needed to invalidate the memoization, not needed in production
      subject.namespace.instance_variable_set(:@custom_emoji_url_by_name, nil)

      new_emoji = build(:custom_emoji, name: subject.name, namespace: subject.namespace)

      expect(new_emoji).not_to be_valid
    end
  end

  describe '#expire_cache' do
    it 'expires cache after save' do
      expect_any_instance_of(Namespace).to receive(:expire_custom_emoji_cache).once

      create(:custom_emoji)
    end
  end

  describe 'with subgroup' do
    let(:parent_group) { create(:group) }
    let(:subgroup) { create(:group, parent: parent_group) }

    before do
      create(:custom_emoji, namespace: parent_group)
    end

    context 'when subgroup has no custom emoji' do
      it 'retrieves custom emoji when parent group has custom emoji' do
        expect(described_class.for_namespace(subgroup.id).count).to be 1
      end
    end

    context 'when subgroup has custom emoji' do
      before do
        create(:custom_emoji, namespace: subgroup)
      end

      it 'retrieves both parent and subgroup custom emoji for subgroup' do
        expect(described_class.for_namespace(subgroup.id).count).to be 2
      end

      it 'does not retrieve subgroup custom emoji for parent' do
        expect(described_class.for_namespace(parent_group.id).count).to be 1
      end

      it 'exeutees only one query' do
        count = ActiveRecord::QueryRecorder.new { described_class.for_namespace(subgroup.id) }.count

        expect(count).to be(1)
      end
    end
  end
end
