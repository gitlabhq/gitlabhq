# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Operations::FeatureFlagScope do
  describe 'associations' do
    it { is_expected.to belong_to(:feature_flag) }
  end

  describe 'validations' do
    context 'when duplicate environment scope is going to be created' do
      let!(:existing_feature_flag_scope) do
        create(:operations_feature_flag_scope)
      end

      let(:new_feature_flag_scope) do
        build(:operations_feature_flag_scope,
          feature_flag: existing_feature_flag_scope.feature_flag,
          environment_scope: existing_feature_flag_scope.environment_scope)
      end

      it 'validates uniqueness of environment scope' do
        new_feature_flag_scope.save

        expect(new_feature_flag_scope.errors[:environment_scope])
          .to include("(#{existing_feature_flag_scope.environment_scope})" \
                      " has already been taken")
      end
    end

    context 'when environment scope of a default scope is updated' do
      let!(:feature_flag) { create(:operations_feature_flag, :legacy_flag) }
      let!(:scope_default) { feature_flag.default_scope }

      it 'keeps default scope intact' do
        scope_default.update(environment_scope: 'review/*')

        expect(scope_default.errors[:environment_scope])
          .to include("cannot be changed from default scope")
      end
    end

    context 'when a default scope is destroyed' do
      let!(:feature_flag) { create(:operations_feature_flag, :legacy_flag) }
      let!(:scope_default) { feature_flag.default_scope }

      it 'prevents from destroying the default scope' do
        expect { scope_default.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end

    describe 'strategy validations' do
      it 'handles null strategies which can occur while adding the column during migration' do
        scope = create(:operations_feature_flag_scope, active: true)
        allow(scope).to receive(:strategies).and_return(nil)

        scope.active = false
        scope.save

        expect(scope.errors[:strategies]).to be_empty
      end

      it 'validates multiple strategies' do
        feature_flag = create(:operations_feature_flag)
        scope = described_class.create(feature_flag: feature_flag,
                                       environment_scope: 'production', active: true,
                                       strategies: [{ name: "default", parameters: {} },
                                                    { name: "invalid", parameters: {} }])

        expect(scope.errors[:strategies]).not_to be_empty
      end

      where(:invalid_value) do
        [{}, 600, "bad", [{ name: 'default', parameters: {} }, 300]]
      end
      with_them do
        it 'must be an array of strategy hashes' do
          scope = create(:operations_feature_flag_scope)

          scope.strategies = invalid_value
          scope.save

          expect(scope.errors[:strategies]).to eq(['must be an array of strategy hashes'])
        end
      end

      describe 'name' do
        using RSpec::Parameterized::TableSyntax

        where(:name, :params, :expected) do
          'default'              | {}                                       | []
          'gradualRolloutUserId' | { groupId: 'mygroup', percentage: '50' } | []
          'userWithId'           | { userIds: 'sam' }                       | []
          5                      | nil                                      | ['strategy name is invalid']
          nil                    | nil                                      | ['strategy name is invalid']
          "nothing"              | nil                                      | ['strategy name is invalid']
          ""                     | nil                                      | ['strategy name is invalid']
          40.0                   | nil                                      | ['strategy name is invalid']
          {}                     | nil                                      | ['strategy name is invalid']
          []                     | nil                                      | ['strategy name is invalid']
        end
        with_them do
          it 'must be one of "default", "gradualRolloutUserId", or "userWithId"' do
            feature_flag = create(:operations_feature_flag)
            scope = described_class.create(feature_flag: feature_flag,
                                           environment_scope: 'production', active: true,
                                           strategies: [{ name: name, parameters: params }])

            expect(scope.errors[:strategies]).to eq(expected)
          end
        end
      end

      describe 'parameters' do
        context 'when the strategy name is gradualRolloutUserId' do
          it 'must have parameters' do
            feature_flag = create(:operations_feature_flag)
            scope = described_class.create(feature_flag: feature_flag,
                                           environment_scope: 'production', active: true,
                                           strategies: [{ name: 'gradualRolloutUserId' }])

            expect(scope.errors[:strategies]).to eq(['parameters are invalid'])
          end

          where(:invalid_parameters) do
            [nil, {}, { percentage: '40', groupId: 'mygroup', userIds: '4' }, { percentage: '40' },
             { percentage: '40', groupId: 'mygroup', extra: nil }, { groupId: 'mygroup' }]
          end
          with_them do
            it 'must have valid parameters for the strategy' do
              feature_flag = create(:operations_feature_flag)
              scope = described_class.create(feature_flag: feature_flag,
                                             environment_scope: 'production', active: true,
                                             strategies: [{ name: 'gradualRolloutUserId',
                                                            parameters: invalid_parameters }])

              expect(scope.errors[:strategies]).to eq(['parameters are invalid'])
            end
          end

          it 'allows the parameters in any order' do
            feature_flag = create(:operations_feature_flag)
            scope = described_class.create(feature_flag: feature_flag,
                                           environment_scope: 'production', active: true,
                                           strategies: [{ name: 'gradualRolloutUserId',
                                                          parameters: { percentage: '10', groupId: 'mygroup' } }])

            expect(scope.errors[:strategies]).to be_empty
          end

          describe 'percentage' do
            where(:invalid_value) do
              [50, 40.0, { key: "value" }, "garbage", "00", "01", "101", "-1", "-10", "0100",
               "1000", "10.0", "5%", "25%", "100hi", "e100", "30m", " ", "\r\n", "\n", "\t",
               "\n10", "20\n", "\n100", "100\n", "\n  ", nil]
            end
            with_them do
              it 'must be a string value between 0 and 100 inclusive and without a percentage sign' do
                feature_flag = create(:operations_feature_flag)
                scope = described_class.create(feature_flag: feature_flag,
                                               environment_scope: 'production', active: true,
                                               strategies: [{ name: 'gradualRolloutUserId',
                                                              parameters: { groupId: 'mygroup', percentage: invalid_value } }])

                expect(scope.errors[:strategies]).to eq(['percentage must be a string between 0 and 100 inclusive'])
              end
            end

            where(:valid_value) do
              %w[0 1 10 38 100 93]
            end
            with_them do
              it 'must be a string value between 0 and 100 inclusive and without a percentage sign' do
                feature_flag = create(:operations_feature_flag)
                scope = described_class.create(feature_flag: feature_flag,
                                               environment_scope: 'production', active: true,
                                               strategies: [{ name: 'gradualRolloutUserId',
                                                              parameters: { groupId: 'mygroup', percentage: valid_value } }])

                expect(scope.errors[:strategies]).to eq([])
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
                feature_flag = create(:operations_feature_flag)
                scope = described_class.create(feature_flag: feature_flag,
                                               environment_scope: 'production', active: true,
                                               strategies: [{ name: 'gradualRolloutUserId',
                                                              parameters: { groupId: invalid_value, percentage: '40' } }])

                expect(scope.errors[:strategies]).to eq(['groupId parameter is invalid'])
              end
            end

            where(:valid_value) do
              ["somegroup", "anothergroup", "okay", "g", "a" * 32]
            end
            with_them do
              it 'must be a string value of up to 32 lowercase characters' do
                feature_flag = create(:operations_feature_flag)
                scope = described_class.create(feature_flag: feature_flag,
                                               environment_scope: 'production', active: true,
                                               strategies: [{ name: 'gradualRolloutUserId',
                                                              parameters: { groupId: valid_value, percentage: '40' } }])

                expect(scope.errors[:strategies]).to eq([])
              end
            end
          end
        end

        context 'when the strategy name is userWithId' do
          it 'must have parameters' do
            feature_flag = create(:operations_feature_flag)
            scope = described_class.create(feature_flag: feature_flag,
                                           environment_scope: 'production', active: true,
                                           strategies: [{ name: 'userWithId' }])

            expect(scope.errors[:strategies]).to eq(['parameters are invalid'])
          end

          where(:invalid_parameters) do
            [nil, { userIds: 'sam', percentage: '40' }, { userIds: 'sam', some: 'param' }, { percentage: '40' }, {}]
          end
          with_them do
            it 'must have valid parameters for the strategy' do
              feature_flag = create(:operations_feature_flag)
              scope = described_class.create(feature_flag: feature_flag,
                                             environment_scope: 'production', active: true,
                                             strategies: [{ name: 'userWithId', parameters: invalid_parameters }])

              expect(scope.errors[:strategies]).to eq(['parameters are invalid'])
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
                feature_flag = create(:operations_feature_flag)
                scope = described_class.create(feature_flag: feature_flag,
                                               environment_scope: 'production', active: true,
                                               strategies: [{ name: 'userWithId', parameters: { userIds: valid_value } }])

                expect(scope.errors[:strategies]).to be_empty
              end
            end

            where(:invalid_value) do
              [1, 2.5, {}, [], nil, "123\n456", "1,2,3,12\t3", "\n", "\n\r",
               "joe\r,sam", "1,2,2", "1,,2", "1,2,,,,", "b" * 257, "1, ,2", "tim,    ,7", " ",
               "    ", " ,1", "1,  ", " leading,1", "1,trailing  ", "1, both ,2"]
            end
            with_them do
              it 'is invalid' do
                feature_flag = create(:operations_feature_flag)
                scope = described_class.create(feature_flag: feature_flag,
                                               environment_scope: 'production', active: true,
                                               strategies: [{ name: 'userWithId', parameters: { userIds: invalid_value } }])

                expect(scope.errors[:strategies]).to include(
                  'userIds must be a string of unique comma separated values each 256 characters or less'
                )
              end
            end
          end
        end

        context 'when the strategy name is default' do
          it 'must have parameters' do
            feature_flag = create(:operations_feature_flag)
            scope = described_class.create(feature_flag: feature_flag,
                                           environment_scope: 'production', active: true,
                                           strategies: [{ name: 'default' }])

            expect(scope.errors[:strategies]).to eq(['parameters are invalid'])
          end

          where(:invalid_value) do
            [{ groupId: "hi", percentage: "7" }, "", "nothing", 7, nil, [], 2.5]
          end
          with_them do
            it 'must be empty' do
              feature_flag = create(:operations_feature_flag)
              scope = described_class.create(feature_flag: feature_flag,
                                             environment_scope: 'production', active: true,
                                             strategies: [{ name: 'default',
                                                            parameters: invalid_value }])

              expect(scope.errors[:strategies]).to eq(['parameters are invalid'])
            end
          end

          it 'must be empty' do
            feature_flag = create(:operations_feature_flag)
            scope = described_class.create(feature_flag: feature_flag,
                                           environment_scope: 'production', active: true,
                                           strategies: [{ name: 'default',
                                                          parameters: {} }])

            expect(scope.errors[:strategies]).to be_empty
          end
        end
      end
    end
  end

  describe '.enabled' do
    subject { described_class.enabled }

    let!(:feature_flag_scope) do
      create(:operations_feature_flag_scope, active: active)
    end

    context 'when scope is active' do
      let(:active) { true }

      it 'returns the scope' do
        is_expected.to include(feature_flag_scope)
      end
    end

    context 'when scope is inactive' do
      let(:active) { false }

      it 'returns an empty array' do
        is_expected.not_to include(feature_flag_scope)
      end
    end
  end

  describe '.disabled' do
    subject { described_class.disabled }

    let!(:feature_flag_scope) do
      create(:operations_feature_flag_scope, active: active)
    end

    context 'when scope is active' do
      let(:active) { true }

      it 'returns an empty array' do
        is_expected.not_to include(feature_flag_scope)
      end
    end

    context 'when scope is inactive' do
      let(:active) { false }

      it 'returns the scope' do
        is_expected.to include(feature_flag_scope)
      end
    end
  end

  describe '.for_unleash_client' do
    it 'returns scopes for the specified project' do
      project1 = create(:project)
      project2 = create(:project)
      expected_feature_flag = create(:operations_feature_flag, project: project1)
      create(:operations_feature_flag, project: project2)

      scopes = described_class.for_unleash_client(project1, 'sandbox').to_a

      expect(scopes).to contain_exactly(*expected_feature_flag.scopes)
    end

    it 'returns a scope that matches exactly over a match with a wild card' do
      project = create(:project)
      feature_flag = create(:operations_feature_flag, project: project)
      create(:operations_feature_flag_scope, feature_flag: feature_flag, environment_scope: 'production*')
      expected_scope = create(:operations_feature_flag_scope, feature_flag: feature_flag, environment_scope: 'production')

      scopes = described_class.for_unleash_client(project, 'production').to_a

      expect(scopes).to contain_exactly(expected_scope)
    end
  end
end
