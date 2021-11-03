# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Operations::FeatureFlags::UserList do
  subject { create(:operations_feature_flag_user_list) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
    it { is_expected.to validate_length_of(:name).is_at_least(1).is_at_most(255) }

    describe 'user_xids' do
      where(:valid_value) do
        ["", "sam", "1", "a", "uuid-of-some-kind", "sam,fred,tom,jane,joe,mike",
         "gitlab@example.com", "123,4", "UPPER,Case,charActeRS", "0",
         "$valid$email#2345#$%..{}+=-)?\\/@example.com", "spaces allowed",
         "a" * 256, "a,#{'b' * 256},ccc", "many    spaces"]
      end
      with_them do
        it 'is valid with a string of comma separated values' do
          user_list = build(:operations_feature_flag_user_list, user_xids: valid_value)

          expect(user_list).to be_valid
        end
      end

      where(:typecast_value) do
        [1, 2.5, {}, []]
      end
      with_them do
        it 'automatically casts values of other types' do
          user_list = build(:operations_feature_flag_user_list, user_xids: typecast_value)

          expect(user_list).to be_valid

          expect(user_list.user_xids).to eq(typecast_value.to_s)
        end
      end

      where(:invalid_value) do
        [nil, "123\n456", "1,2,3,12\t3", "\n", "\n\r",
         "joe\r,sam", "1,2,2", "1,,2", "1,2,,,,", "b" * 257, "1, ,2", "tim,    ,7", " ",
         "    ", " ,1", "1,  ", " leading,1", "1,trailing  ", "1, both ,2"]
      end
      with_them do
        it 'is invalid' do
          user_list = build(:operations_feature_flag_user_list, user_xids: invalid_value)

          expect(user_list).to be_invalid

          expect(user_list.errors[:user_xids]).to include(
            'user_xids must be a string of unique comma separated values each 256 characters or less'
          )
        end
      end
    end
  end

  describe 'url_helpers' do
    it 'generates paths based on the internal id' do
      create(:operations_feature_flag_user_list)
      project_b = create(:project)
      list_b = create(:operations_feature_flag_user_list, project: project_b)

      path = ::Gitlab::Routing.url_helpers.project_feature_flags_user_list_path(project_b, list_b)

      expect(path).to eq("/#{project_b.full_path}/-/feature_flags_user_lists/#{list_b.iid}")
    end
  end

  describe '#destroy' do
    it 'deletes the model if it is not associated with any feature flag strategies' do
      project = create(:project)
      user_list = described_class.create!(project: project, name: 'My User List', user_xids: 'user1,user2')

      user_list.destroy!

      expect(described_class.count).to eq(0)
    end

    it 'does not delete the model if it is associated with a feature flag strategy' do
      project = create(:project)
      user_list = described_class.create!(project: project, name: 'My User List', user_xids: 'user1,user2')
      feature_flag = create(:operations_feature_flag, :new_version_flag, project: project)
      strategy = create(:operations_strategy, feature_flag: feature_flag, name: 'gitlabUserList', user_list: user_list)

      user_list.destroy # rubocop:disable Rails/SaveBang

      expect(described_class.count).to eq(1)
      expect(::Operations::FeatureFlags::StrategyUserList.count).to eq(1)
      expect(strategy.reload.user_list).to eq(user_list)
      expect(strategy.valid?).to eq(true)
    end
  end

  describe '.for_name_like' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user_list_one) { create(:operations_feature_flag_user_list, project: project, name: 'one') }
    let_it_be(:user_list_two) { create(:operations_feature_flag_user_list, project: project, name: 'list_two') }
    let_it_be(:user_list_three) { create(:operations_feature_flag_user_list, project: project, name: 'list_three') }

    it 'returns a found name' do
      lists = project.operations_feature_flags_user_lists.for_name_like('list')

      expect(lists).to contain_exactly(user_list_two, user_list_three)
    end

    it 'returns an empty array when no lists match the query' do
      lists = project.operations_feature_flags_user_lists.for_name_like('no match')

      expect(lists).to be_empty
    end
  end

  it_behaves_like 'AtomicInternalId' do
    let(:internal_id_attribute) { :iid }
    let(:instance) { build(:operations_feature_flag_user_list) }
    let(:scope) { :project }
    let(:scope_attrs) { { project: instance.project } }
    let(:usage) { :operations_user_lists }
  end
end
