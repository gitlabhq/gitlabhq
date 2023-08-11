# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Operations::FeatureFlags::Strategy do
  let_it_be(:project) { create(:project) }
  let_it_be(:feature_flag) { create(:operations_feature_flag, project: project) }

  describe 'validations' do
    it do
      is_expected.to validate_inclusion_of(:name)
        .in_array(%w[default gradualRolloutUserId flexibleRollout userWithId gitlabUserList])
        .with_message('strategy name is invalid')
    end

    describe 'parameters' do
      context 'when the strategy name is invalid' do
        where(:invalid_name) do
          [nil, {}, [], 'nothing', 3]
        end
        with_them do
          it 'skips parameters validation' do
            strategy = build(
              :operations_strategy,
              feature_flag: feature_flag,
              name: invalid_name,
              parameters: { bad: 'params' }
            )

            expect(strategy).to be_invalid

            expect(strategy.errors[:name]).to eq([s_('Validation|strategy name is invalid')])
            expect(strategy.errors[:parameters]).to be_empty
          end
        end
      end

      context 'when the strategy name is gradualRolloutUserId' do
        where(:invalid_parameters) do
          [nil, {}, { percentage: '40', groupId: 'mygroup', userIds: '4' }, { percentage: '40' },
           { percentage: '40', groupId: 'mygroup', extra: nil }, { groupId: 'mygroup' }]
        end
        with_them do
          it 'must have valid parameters for the strategy' do
            strategy = build(
              :operations_strategy,
              :gradual_rollout,
              feature_flag: feature_flag,
              parameters: invalid_parameters
            )

            expect(strategy).to be_invalid

            expect(strategy.errors[:parameters]).to eq([s_('Validation|parameters are invalid')])
          end
        end

        it 'allows the parameters in any order' do
          strategy = build(
            :operations_strategy,
            :gradual_rollout,
            feature_flag: feature_flag,
            parameters: { percentage: '10', groupId: 'mygroup' }
          )

          expect(strategy).to be_valid
        end

        describe 'percentage' do
          where(:invalid_value) do
            [50, 40.0, { key: "value" }, "garbage", "101", "-1", "-10", "1000", "10.0", "5%", "25%",
             "100hi", "e100", "30m", " ", "\r\n", "\n", "\t", "\n10", "20\n", "\n100", "100\n",
             "\n  ", nil]
          end
          with_them do
            it 'must be a string value between 0 and 100 inclusive and without a percentage sign' do
              strategy = build(
                :operations_strategy,
                :gradual_rollout,
                feature_flag: feature_flag,
                parameters: { groupId: 'mygroup', percentage: invalid_value }
              )

              expect(strategy).to be_invalid

              expect(strategy.errors[:parameters]).to eq([
                s_('Validation|percentage must be a string between 0 and 100 inclusive')
              ])
            end
          end

          where(:valid_value) do
            %w[0 1 10 38 100 93]
          end
          with_them do
            it 'must be a string value between 0 and 100 inclusive and without a percentage sign' do
              strategy = build(
                :operations_strategy,
                :gradual_rollout,
                feature_flag: feature_flag,
                parameters: { groupId: 'mygroup', percentage: valid_value }
              )

              expect(strategy).to be_valid
            end
          end
        end

        describe 'groupId' do
          where(:invalid_value) do
            [nil, 4, 50.0, {}, 'spaces bad', 'bad$', '%bad', '<bad', 'bad>', '!bad',
             '.bad', 'Bad', 'bad1', "", " ", "b" * 33, "ba_d", "ba\nd"]
          end
          with_them do
            it 'must be a string value of up to 32 lowercase characters' do
              strategy = build(
                :operations_strategy,
                :gradual_rollout,
                feature_flag: feature_flag,
                parameters: { groupId: invalid_value, percentage: '40' }
              )

              expect(strategy).to be_invalid

              expect(strategy.errors[:parameters]).to eq([s_('Validation|groupId parameter is invalid')])
            end
          end

          where(:valid_value) do
            ["somegroup", "anothergroup", "okay", "g", "a" * 32]
          end
          with_them do
            it 'must be a string value of up to 32 lowercase characters' do
              strategy = build(
                :operations_strategy,
                :gradual_rollout,
                feature_flag: feature_flag,
                parameters: { groupId: valid_value, percentage: '40' }
              )

              expect(strategy).to be_valid
            end
          end
        end
      end

      context 'when the strategy name is flexibleRollout' do
        valid_parameters = { rollout: '40', groupId: 'mygroup', stickiness: 'default' }
        where(
          invalid_parameters: [
            nil,
            {},
            *valid_parameters.to_a.combination(1).to_a.map { |p| p.to_h },
            *valid_parameters.to_a.combination(2).to_a.map { |p| p.to_h },
            { **valid_parameters, userIds: '4' },
            { **valid_parameters, extra: nil }
          ])
        with_them do
          it 'must have valid parameters for the strategy' do
            strategy = build(
              :operations_strategy,
              :flexible_rollout,
              feature_flag: feature_flag,
              parameters: invalid_parameters
            )

            expect(strategy).to be_invalid

            expect(strategy.errors[:parameters]).to eq([s_('Validation|parameters are invalid')])
          end
        end

        [
          [:rollout, '10'],
          [:stickiness, 'default'],
          [:groupId, 'mygroup']
        ].permutation(3).each do |parameters|
          it "allows the parameters in the order #{parameters.map { |p| p.first }.join(', ')}" do
            strategy = build(
              :operations_strategy,
              :flexible_rollout,
              feature_flag: feature_flag,
              parameters: Hash[parameters]
            )

            expect(strategy).to be_valid
          end
        end

        describe 'rollout' do
          where(invalid_value: [50, 40.0, { key: "value" }, "garbage", "101", "-1", " ", "-10",
                                "1000", "10.0", "5%", "25%", "100hi", "e100", "30m", "\r\n",
                                "\n", "\t", "\n10", "20\n", "\n100", "100\n", "\n  ", nil])
          with_them do
            it 'must be a string value between 0 and 100 inclusive and without a percentage sign' do
              parameters = { stickiness: 'default', groupId: 'mygroup', rollout: invalid_value }
              strategy = build(
                :operations_strategy,
                :flexible_rollout,
                feature_flag: feature_flag,
                parameters: parameters
              )

              expect(strategy).to be_invalid

              expect(strategy.errors[:parameters]).to eq([
                s_('Validation|rollout must be a string between 0 and 100 inclusive')
              ])
            end
          end

          where(valid_value: %w[0 1 10 38 100 93])
          with_them do
            it 'must be a string value between 0 and 100 inclusive and without a percentage sign' do
              parameters = { stickiness: 'default', groupId: 'mygroup', rollout: valid_value }
              strategy = build(
                :operations_strategy,
                :flexible_rollout,
                feature_flag: feature_flag,
                parameters: parameters
              )

              expect(strategy).to be_valid
            end
          end
        end

        describe 'groupId' do
          where(invalid_value: [nil, 4, 50.0, {}, 'spaces bad', 'bad$', '%bad', '<bad', 'bad>',
                                '!bad', '.bad', 'Bad', 'bad1', "", " ", "b" * 33, "ba_d", "ba\nd"])
          with_them do
            it 'must be a string value of up to 32 lowercase characters' do
              parameters = { stickiness: 'default', groupId: invalid_value, rollout: '40' }
              strategy = build(
                :operations_strategy,
                :flexible_rollout,
                feature_flag: feature_flag,
                parameters: parameters
              )

              expect(strategy).to be_invalid

              expect(strategy.errors[:parameters]).to eq(['groupId parameter is invalid'])
            end
          end

          where(valid_value: ["somegroup", "anothergroup", "okay", "g", "a" * 32])
          with_them do
            it 'must be a string value of up to 32 lowercase characters' do
              parameters = { stickiness: 'default', groupId: valid_value, rollout: '40' }
              strategy = build(
                :operations_strategy,
                :flexible_rollout,
                feature_flag: feature_flag,
                parameters: parameters
              )

              expect(strategy).to be_valid
            end
          end
        end

        describe 'stickiness' do
          where(invalid_value: [nil, " ", "DEFAULT", "DEFAULT\n", "UserId", "USER", "USERID "])
          with_them do
            it 'must be a string representing a supported stickiness setting' do
              parameters = { stickiness: invalid_value, groupId: 'mygroup', rollout: '40' }
              strategy = build(
                :operations_strategy,
                :flexible_rollout,
                feature_flag: feature_flag,
                parameters: parameters
              )

              expect(strategy).to be_invalid

              expect(strategy.errors[:parameters]).to eq(
                ['stickiness parameter must be default, userId, sessionId, or random'])
            end
          end

          where(valid_value: %w[default userId sessionId random])
          with_them do
            it 'must be a string representing a supported stickiness setting' do
              parameters = { stickiness: valid_value, groupId: 'mygroup', rollout: '40' }
              strategy = build(
                :operations_strategy,
                :flexible_rollout,
                feature_flag: feature_flag,
                parameters: parameters
              )

              expect(strategy).to be_valid
            end
          end
        end
      end

      context 'when the strategy name is userWithId' do
        where(:invalid_parameters) do
          [nil, { userIds: 'sam', percentage: '40' }, { userIds: 'sam', some: 'param' }, { percentage: '40' }, {}]
        end
        with_them do
          it 'must have valid parameters for the strategy' do
            strategy = build(
              :operations_strategy,
              feature_flag: feature_flag,
              name: 'userWithId',
              parameters: invalid_parameters
            )

            expect(strategy).to be_invalid

            expect(strategy.errors[:parameters]).to eq([s_('Validation|parameters are invalid')])
          end
        end

        describe 'userIds' do
          where(:valid_value) do
            ["", "sam", "1", "a", "uuid-of-some-kind", "sam,fred,tom,jane,joe,mike",
             "gitlab@example.com", "123,4", "UPPER,Case,charActeRS", "0",
             "$valid$email#2345#$%..{}+=-)?\\/@example.com", "spaces allowed",
             "a" * 256, "a,#{'b' * 256},ccc", "many    spaces"]
          end
          with_them do
            it 'is valid with a string of comma separated values' do
              strategy = build(
                :operations_strategy,
                feature_flag: feature_flag,
                name: 'userWithId',
                parameters: { userIds: valid_value }
              )

              expect(strategy).to be_valid
            end
          end

          where(:invalid_value) do
            [1, 2.5, {}, [], nil, "123\n456", "1,2,3,12\t3", "\n", "\n\r",
             "joe\r,sam", "1,2,2", "1,,2", "1,2,,,,", "b" * 257, "1, ,2", "tim,    ,7", " ",
             "    ", " ,1", "1,  ", " leading,1", "1,trailing  ", "1, both ,2"]
          end
          with_them do
            it 'is invalid' do
              strategy = build(
                :operations_strategy,
                feature_flag: feature_flag,
                name: 'userWithId',
                parameters: { userIds: invalid_value }
              )

              expect(strategy).to be_invalid

              expect(strategy.errors[:parameters]).to include(
                'userIds must be a string of unique comma separated values each 256 characters or less'
              )
            end
          end
        end
      end

      context 'when the strategy name is default' do
        where(:invalid_value) do
          [{ groupId: "hi", percentage: "7" }, "", "nothing", 7, nil, [], 2.5]
        end
        with_them do
          it 'must be empty' do
            strategy = build(:operations_strategy, :default, feature_flag: feature_flag, parameters: invalid_value)

            expect(strategy).to be_invalid

            expect(strategy.errors[:parameters]).to eq([s_('Validation|parameters are invalid')])
          end
        end

        it 'must be empty' do
          strategy = build(:operations_strategy, :default, feature_flag: feature_flag)

          expect(strategy).to be_valid
        end
      end

      context 'when the strategy name is gitlabUserList' do
        let_it_be(:user_list) { create(:operations_feature_flag_user_list, project: project) }

        where(:invalid_value) do
          [{ groupId: "default", percentage: "7" }, "", "nothing", 7, nil, [], 2.5, { userIds: 'user1' }]
        end
        with_them do
          it 'is invalid' do
            strategy = build(
              :operations_strategy,
              :gitlab_userlist,
              user_list: user_list,
              feature_flag: feature_flag,
              parameters: invalid_value
            )

            expect(strategy).to be_invalid

            expect(strategy.errors[:parameters]).to eq([s_('Validation|parameters are invalid')])
          end
        end

        it 'is valid' do
          strategy = build(
            :operations_strategy,
            :gitlab_userlist,
            user_list: user_list,
            feature_flag: feature_flag
          )

          expect(strategy).to be_valid
        end
      end
    end

    describe 'associations' do
      context 'when name is gitlabUserList' do
        it 'is valid when associated with a user list' do
          user_list = create(:operations_feature_flag_user_list, project: project)
          strategy = build(:operations_strategy, :gitlab_userlist, feature_flag: feature_flag, user_list: user_list)

          expect(strategy).to be_valid
        end

        it 'is invalid without a user list' do
          strategy = build(:operations_strategy, :gitlab_userlist, feature_flag: feature_flag, user_list: nil)

          expect(strategy).to be_invalid

          expect(strategy.errors[:user_list]).to eq(["can't be blank"])
        end

        it 'is invalid when associated with a user list from another project' do
          other_project = create(:project)
          user_list = create(:operations_feature_flag_user_list, project: other_project)
          strategy = build(:operations_strategy, :gitlab_userlist, feature_flag: feature_flag, user_list: user_list)

          expect(strategy).to be_invalid

          expect(strategy.errors[:user_list]).to eq([s_('Validation|must belong to the same project')])
        end
      end

      context 'when name is default' do
        it 'is invalid when associated with a user list' do
          user_list = create(:operations_feature_flag_user_list, project: project)
          strategy = build(:operations_strategy, :default, feature_flag: feature_flag, user_list: user_list)

          expect(strategy).to be_invalid

          expect(strategy.errors[:user_list]).to eq(['must be blank'])
        end

        it 'is valid without a user list' do
          strategy = build(:operations_strategy, :default, feature_flag: feature_flag)

          expect(strategy).to be_valid
        end
      end

      context 'when name is userWithId' do
        it 'is invalid when associated with a user list' do
          user_list = create(:operations_feature_flag_user_list, project: project)
          strategy = build(:operations_strategy, :userwithid, feature_flag: feature_flag, user_list: user_list)

          expect(strategy).to be_invalid

          expect(strategy.errors[:user_list]).to eq(['must be blank'])
        end

        it 'is valid without a user list' do
          strategy = build(:operations_strategy, :userwithid, feature_flag: feature_flag)

          expect(strategy).to be_valid
        end
      end

      context 'when name is gradualRolloutUserId' do
        it 'is invalid when associated with a user list' do
          user_list = create(:operations_feature_flag_user_list, project: project)
          strategy = build(:operations_strategy, :gradual_rollout, feature_flag: feature_flag, user_list: user_list)

          expect(strategy).to be_invalid

          expect(strategy.errors[:user_list]).to eq(['must be blank'])
        end

        it 'is valid without a user list' do
          strategy = build(:operations_strategy, :gradual_rollout, feature_flag: feature_flag)

          expect(strategy).to be_valid
        end
      end

      context 'when name is flexibleRollout' do
        it 'is invalid when associated with a user list' do
          user_list = create(:operations_feature_flag_user_list, project: project)
          strategy = build(:operations_strategy, :flexible_rollout, feature_flag: feature_flag, user_list: user_list)

          expect(strategy).to be_invalid

          expect(strategy.errors[:user_list]).to eq(['must be blank'])
        end

        it 'is valid without a user list' do
          strategy = build(:operations_strategy, :flexible_rollout, feature_flag: feature_flag)

          expect(strategy).to be_valid
        end
      end
    end
  end
end
