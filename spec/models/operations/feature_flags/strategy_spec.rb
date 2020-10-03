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
            strategy = described_class.create(feature_flag: feature_flag,
                                              name: invalid_name, parameters: { bad: 'params' })

            expect(strategy.errors[:name]).to eq(['strategy name is invalid'])
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
            strategy = described_class.create(feature_flag: feature_flag,
                                              name: 'gradualRolloutUserId', parameters: invalid_parameters)

            expect(strategy.errors[:parameters]).to eq(['parameters are invalid'])
          end
        end

        it 'allows the parameters in any order' do
          strategy = described_class.create(feature_flag: feature_flag,
                                            name: 'gradualRolloutUserId',
                                            parameters: { percentage: '10', groupId: 'mygroup' })

          expect(strategy.errors[:parameters]).to be_empty
        end

        describe 'percentage' do
          where(:invalid_value) do
            [50, 40.0, { key: "value" }, "garbage", "101", "-1", "-10", "1000", "10.0", "5%", "25%",
             "100hi", "e100", "30m", " ", "\r\n", "\n", "\t", "\n10", "20\n", "\n100", "100\n",
             "\n  ", nil]
          end
          with_them do
            it 'must be a string value between 0 and 100 inclusive and without a percentage sign' do
              strategy = described_class.create(feature_flag: feature_flag,
                                                name: 'gradualRolloutUserId',
                                                parameters: { groupId: 'mygroup', percentage: invalid_value })

              expect(strategy.errors[:parameters]).to eq(['percentage must be a string between 0 and 100 inclusive'])
            end
          end

          where(:valid_value) do
            %w[0 1 10 38 100 93]
          end
          with_them do
            it 'must be a string value between 0 and 100 inclusive and without a percentage sign' do
              strategy = described_class.create(feature_flag: feature_flag,
                                                name: 'gradualRolloutUserId',
                                                parameters: { groupId: 'mygroup', percentage: valid_value })

              expect(strategy.errors[:parameters]).to eq([])
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
              strategy = described_class.create(feature_flag: feature_flag,
                                                name: 'gradualRolloutUserId',
                                                parameters: { groupId: invalid_value, percentage: '40' })

              expect(strategy.errors[:parameters]).to eq(['groupId parameter is invalid'])
            end
          end

          where(:valid_value) do
            ["somegroup", "anothergroup", "okay", "g", "a" * 32]
          end
          with_them do
            it 'must be a string value of up to 32 lowercase characters' do
              strategy = described_class.create(feature_flag: feature_flag,
                                                name: 'gradualRolloutUserId',
                                                parameters: { groupId: valid_value, percentage: '40' })

              expect(strategy.errors[:parameters]).to eq([])
            end
          end
        end
      end

      context 'when the strategy name is flexibleRollout' do
        valid_parameters = { rollout: '40', groupId: 'mygroup', stickiness: 'DEFAULT' }
        where(invalid_parameters: [
          nil,
          {},
          *valid_parameters.to_a.combination(1).to_a.map { |p| p.to_h },
          *valid_parameters.to_a.combination(2).to_a.map { |p| p.to_h },
          { **valid_parameters, userIds: '4' },
          { **valid_parameters, extra: nil }
        ])
        with_them do
          it 'must have valid parameters for the strategy' do
            strategy = described_class.create(feature_flag: feature_flag,
                                              name: 'flexibleRollout',
                                              parameters: invalid_parameters)

            expect(strategy.errors[:parameters]).to eq(['parameters are invalid'])
          end
        end

        [
          [:rollout, '10'],
          [:stickiness, 'DEFAULT'],
          [:groupId, 'mygroup']
        ].permutation(3).each do |parameters|
          it "allows the parameters in the order #{parameters.map { |p| p.first }.join(', ')}" do
            strategy = described_class.create(feature_flag: feature_flag,
                                              name: 'flexibleRollout',
                                              parameters: Hash[parameters])

            expect(strategy.errors[:parameters]).to be_empty
          end
        end

        describe 'rollout' do
          where(invalid_value: [50, 40.0, { key: "value" }, "garbage", "101", "-1", " ", "-10",
                                "1000", "10.0", "5%", "25%", "100hi", "e100", "30m", "\r\n",
                                "\n", "\t", "\n10", "20\n", "\n100", "100\n", "\n  ", nil])
          with_them do
            it 'must be a string value between 0 and 100 inclusive and without a percentage sign' do
              parameters = { stickiness: 'DEFAULT', groupId: 'mygroup', rollout: invalid_value }
              strategy = described_class.create(feature_flag: feature_flag,
                                                name: 'flexibleRollout',
                                                parameters: parameters)

              expect(strategy.errors[:parameters]).to eq([
                'rollout must be a string between 0 and 100 inclusive'
              ])
            end
          end

          where(valid_value: %w[0 1 10 38 100 93])
          with_them do
            it 'must be a string value between 0 and 100 inclusive and without a percentage sign' do
              parameters = { stickiness: 'DEFAULT', groupId: 'mygroup', rollout: valid_value }
              strategy = described_class.create(feature_flag: feature_flag,
                                                name: 'flexibleRollout',
                                                parameters: parameters)

              expect(strategy.errors[:parameters]).to eq([])
            end
          end
        end

        describe 'groupId' do
          where(invalid_value: [nil, 4, 50.0, {}, 'spaces bad', 'bad$', '%bad', '<bad', 'bad>',
                                '!bad', '.bad', 'Bad', 'bad1', "", " ", "b" * 33, "ba_d", "ba\nd"])
          with_them do
            it 'must be a string value of up to 32 lowercase characters' do
              parameters = { stickiness: 'DEFAULT', groupId: invalid_value, rollout: '40' }
              strategy = described_class.create(feature_flag: feature_flag,
                                                name: 'flexibleRollout',
                                                parameters: parameters)

              expect(strategy.errors[:parameters]).to eq(['groupId parameter is invalid'])
            end
          end

          where(valid_value: ["somegroup", "anothergroup", "okay", "g", "a" * 32])
          with_them do
            it 'must be a string value of up to 32 lowercase characters' do
              parameters = { stickiness: 'DEFAULT', groupId: valid_value, rollout: '40' }
              strategy = described_class.create(feature_flag: feature_flag,
                                                name: 'flexibleRollout',
                                                parameters: parameters)

              expect(strategy.errors[:parameters]).to eq([])
            end
          end
        end

        describe 'stickiness' do
          where(invalid_value: [nil, " ", "default", "DEFAULT\n", "UserId", "USER", "USERID "])
          with_them do
            it 'must be a string representing a supported stickiness setting' do
              parameters = { stickiness: invalid_value, groupId: 'mygroup', rollout: '40' }
              strategy = described_class.create(feature_flag: feature_flag,
                                                name: 'flexibleRollout',
                                                parameters: parameters)

              expect(strategy.errors[:parameters]).to eq([
                'stickiness parameter must be DEFAULT, USERID, SESSIONID, or RANDOM'
              ])
            end
          end

          where(valid_value: %w[DEFAULT USERID SESSIONID RANDOM])
          with_them do
            it 'must be a string representing a supported stickiness setting' do
              parameters = { stickiness: valid_value, groupId: 'mygroup', rollout: '40' }
              strategy = described_class.create(feature_flag: feature_flag,
                                                name: 'flexibleRollout',
                                                parameters: parameters)

              expect(strategy.errors[:parameters]).to eq([])
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
            strategy = described_class.create(feature_flag: feature_flag,
                                              name: 'userWithId', parameters: invalid_parameters)

            expect(strategy.errors[:parameters]).to eq(['parameters are invalid'])
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
              strategy = described_class.create(feature_flag: feature_flag,
                                                name: 'userWithId', parameters: { userIds: valid_value })

              expect(strategy.errors[:parameters]).to be_empty
            end
          end

          where(:invalid_value) do
            [1, 2.5, {}, [], nil, "123\n456", "1,2,3,12\t3", "\n", "\n\r",
             "joe\r,sam", "1,2,2", "1,,2", "1,2,,,,", "b" * 257, "1, ,2", "tim,    ,7", " ",
             "    ", " ,1", "1,  ", " leading,1", "1,trailing  ", "1, both ,2"]
          end
          with_them do
            it 'is invalid' do
              strategy = described_class.create(feature_flag: feature_flag,
                                                name: 'userWithId', parameters: { userIds: invalid_value })

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
            strategy = described_class.create(feature_flag: feature_flag,
                                              name: 'default',
                                              parameters: invalid_value)

            expect(strategy.errors[:parameters]).to eq(['parameters are invalid'])
          end
        end

        it 'must be empty' do
          strategy = described_class.create(feature_flag: feature_flag,
                                            name: 'default',
                                            parameters: {})

          expect(strategy.errors[:parameters]).to be_empty
        end
      end

      context 'when the strategy name is gitlabUserList' do
        where(:invalid_value) do
          [{ groupId: "default", percentage: "7" }, "", "nothing", 7, nil, [], 2.5, { userIds: 'user1' }]
        end
        with_them do
          it 'must be empty' do
            strategy = described_class.create(feature_flag: feature_flag,
                                              name: 'gitlabUserList',
                                              parameters: invalid_value)

            expect(strategy.errors[:parameters]).to eq(['parameters are invalid'])
          end
        end

        it 'must be empty' do
          strategy = described_class.create(feature_flag: feature_flag,
                                            name: 'gitlabUserList',
                                            parameters: {})

          expect(strategy.errors[:parameters]).to be_empty
        end
      end
    end

    describe 'associations' do
      context 'when name is gitlabUserList' do
        it 'is valid when associated with a user list' do
          user_list = create(:operations_feature_flag_user_list, project: project)
          strategy = described_class.create(feature_flag: feature_flag,
                                            name: 'gitlabUserList',
                                            user_list: user_list,
                                            parameters: {})

          expect(strategy.errors[:user_list]).to be_empty
        end

        it 'is invalid without a user list' do
          strategy = described_class.create(feature_flag: feature_flag,
                                            name: 'gitlabUserList',
                                            parameters: {})

          expect(strategy.errors[:user_list]).to eq(["can't be blank"])
        end

        it 'is invalid when associated with a user list from another project' do
          other_project = create(:project)
          user_list = create(:operations_feature_flag_user_list, project: other_project)
          strategy = described_class.create(feature_flag: feature_flag,
                                            name: 'gitlabUserList',
                                            user_list: user_list,
                                            parameters: {})

          expect(strategy.errors[:user_list]).to eq(['must belong to the same project'])
        end
      end

      context 'when name is default' do
        it 'is invalid when associated with a user list' do
          user_list = create(:operations_feature_flag_user_list, project: project)
          strategy = described_class.create(feature_flag: feature_flag,
                                            name: 'default',
                                            user_list: user_list,
                                            parameters: {})

          expect(strategy.errors[:user_list]).to eq(['must be blank'])
        end

        it 'is valid without a user list' do
          strategy = described_class.create(feature_flag: feature_flag,
                                            name: 'default',
                                            parameters: {})

          expect(strategy.errors[:user_list]).to be_empty
        end
      end

      context 'when name is userWithId' do
        it 'is invalid when associated with a user list' do
          user_list = create(:operations_feature_flag_user_list, project: project)
          strategy = described_class.create(feature_flag: feature_flag,
                                            name: 'userWithId',
                                            user_list: user_list,
                                            parameters: { userIds: 'user1' })

          expect(strategy.errors[:user_list]).to eq(['must be blank'])
        end

        it 'is valid without a user list' do
          strategy = described_class.create(feature_flag: feature_flag,
                                            name: 'userWithId',
                                            parameters: { userIds: 'user1' })

          expect(strategy.errors[:user_list]).to be_empty
        end
      end

      context 'when name is gradualRolloutUserId' do
        it 'is invalid when associated with a user list' do
          user_list = create(:operations_feature_flag_user_list, project: project)
          strategy = described_class.create(feature_flag: feature_flag,
                                            name: 'gradualRolloutUserId',
                                            user_list: user_list,
                                            parameters: { groupId: 'default', percentage: '10' })

          expect(strategy.errors[:user_list]).to eq(['must be blank'])
        end

        it 'is valid without a user list' do
          strategy = described_class.create(feature_flag: feature_flag,
                                            name: 'gradualRolloutUserId',
                                            parameters: { groupId: 'default', percentage: '10' })

          expect(strategy.errors[:user_list]).to be_empty
        end
      end

      context 'when name is flexibleRollout' do
        it 'is invalid when associated with a user list' do
          user_list = create(:operations_feature_flag_user_list, project: project)
          strategy = described_class.create(feature_flag: feature_flag,
                                            name: 'flexibleRollout',
                                            user_list: user_list,
                                            parameters: { groupId: 'default',
                                                          rollout: '10',
                                                          stickiness: 'DEFAULT' })

          expect(strategy.errors[:user_list]).to eq(['must be blank'])
        end

        it 'is valid without a user list' do
          strategy = described_class.create(feature_flag: feature_flag,
                                            name: 'flexibleRollout',
                                            parameters: { groupId: 'default',
                                                          rollout: '10',
                                                          stickiness: 'DEFAULT' })

          expect(strategy.errors[:user_list]).to be_empty
        end
      end
    end
  end
end
