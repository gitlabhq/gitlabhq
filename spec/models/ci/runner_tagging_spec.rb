# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerTagging, feature_category: :runner_core do
  let_it_be(:group) { create(:group) }

  it { is_expected.to belong_to(:runner).optional(false) }
  it { is_expected.to belong_to(:tag).optional(false) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:runner_type) }
    it { is_expected.to validate_presence_of(:tag_name) }
    it { is_expected.to validate_length_of(:tag_name).is_at_most(described_class::MAX_NAME_LENGTH) }
    it { is_expected.to validate_presence_of(:organization_id).on([:create, :update]) }

    describe 'organization_id' do
      subject(:runner_tagging) { runner.taggings.first }

      context 'when runner_type is instance_type' do
        let(:runner) { create(:ci_runner, :instance, tag_list: ['postgres']) }

        it { is_expected.to be_valid }

        context 'and organization_id is not nil' do
          before do
            runner_tagging.organization_id = non_existing_record_id
          end

          it { is_expected.to be_invalid }
        end
      end

      context 'when runner_type is group_type' do
        let(:runner) { create(:ci_runner, :group, groups: [group], tag_list: ['postgres']) }

        it { is_expected.to be_valid }

        context 'and organization_id is nil' do
          before do
            runner_tagging.organization_id = nil
          end

          it { is_expected.to be_invalid }
        end
      end
    end

    describe 'tag_name' do
      subject(:runner_tagging) { runner.taggings.first }

      let_it_be(:runner) { create(:ci_runner, :instance, tag_list: ['postgres']) }

      it 'sets tag_name to tag name' do
        expect(runner_tagging).to be_valid
        expect(runner_tagging.tag_name).to eq('postgres')
      end

      it 'updates existing tag_name' do
        runner_tagging.tag_name = 'new-name'
        runner_tagging.validate!
        expect(runner_tagging.tag_name).to eq('new-name')
      end

      context 'when tag is missing' do
        let_it_be(:runner) { create(:ci_runner, tag_list: ['missing-tag']) }

        before do
          runner_tagging.tag.destroy!
        end

        it 'handles missing tag gracefully' do
          expect do
            runner_tagging.validate!
          end.not_to change { runner_tagging.tag_name }.from('missing-tag')
        end
      end

      context 'when tag name is different from existing tagging name' do
        let_it_be(:runner) { create(:ci_runner, :group, groups: [group], tag_list: ['ruby']) }

        before do
          runner_tagging.tag.update!(name: 'golang')
        end

        it 'does not update tag_name to tag name on validation' do
          expect { runner_tagging.validate! }
            .not_to change { runner_tagging.tag_name }.from('ruby')
        end
      end

      context "when tag name exceeds #{described_class::MAX_NAME_LENGTH} characters" do
        let(:long_tag_name) { 'a' * (described_class::MAX_NAME_LENGTH + 20) }
        let(:tag) { create(:ci_tag, name: 'a') }
        let(:runner_tagging) { build(:ci_runner_tagging, runner: runner, tag: tag, tag_name: nil) }

        before do
          tag.update_columns(name: long_tag_name)
        end

        it 'makes tagging invalid' do
          expect(tag).not_to be_valid
          expect(runner_tagging).not_to be_valid
        end
      end
    end
  end

  describe 'partitioning' do
    context 'with runner' do
      let_it_be(:runner) { FactoryBot.build(:ci_runner, :group, groups: [group]) }
      let_it_be(:runner_tagging) { FactoryBot.build(:ci_runner_tagging, runner: runner) }

      it 'sets runner_type to the current partition value' do
        expect { runner_tagging.valid? }.to change { runner_tagging.runner_type }.to('group_type')
      end

      context 'when it is already set' do
        let_it_be(:runner_tagging) { FactoryBot.build(:ci_runner_tagging, runner_type: :project_type) }

        it 'does not change the runner_type value' do
          expect { runner_tagging.valid? }.not_to change { runner_tagging.runner_type }
        end
      end
    end
  end

  describe 'loose foreign keys' do
    context 'with loose foreign key on tags.id' do
      it_behaves_like 'cleanup by a loose foreign key' do
        let(:lfk_column) { :tag_id }
        let_it_be(:runner) { create(:ci_runner, :group, groups: [group]) }
        let_it_be(:parent) { create(:ci_tag, name: 'ruby') }
        let_it_be(:model) { create(:ci_runner_tagging, runner: runner, tag_id: parent.id) }
      end
    end

    context 'with loose foreign key on organizations.id' do
      context 'with group runner type' do
        it_behaves_like 'cleanup by a loose foreign key' do
          let(:model_table_name) { 'ci_runner_taggings' }
          let(:lfk_column) { :organization_id }
          let_it_be(:parent) { create(:organization) }
          let_it_be(:group) { create(:group, organization: parent) }
          let_it_be(:runner) { create(:ci_runner, :group, groups: [group]) }
          let_it_be(:tag) { create(:ci_tag, name: 'ruby') }
          let_it_be(:model) do
            create(:ci_runner_tagging, runner: runner, runner_type: runner.runner_type,
              organization_id: parent.id, tag_id: tag.id)
          end
        end
      end

      context 'with project runner type' do
        it_behaves_like 'cleanup by a loose foreign key' do
          let(:model_table_name) { 'ci_runner_taggings' }
          let(:lfk_column) { :organization_id }
          let_it_be(:parent) { create(:organization) }
          let_it_be(:group) { create(:group, organization: parent) }
          let_it_be(:project) { create(:project, group: group) }
          let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }
          let_it_be(:tag) { create(:ci_tag, name: 'ruby') }
          let_it_be(:model) do
            create(:ci_runner_tagging, runner: runner, runner_type: runner.runner_type,
              organization_id: parent.id, tag_id: tag.id)
          end
        end
      end
    end
  end

  describe 'scopes' do
    describe '.for_runner' do
      subject(:for_runner) { described_class.for_runner(runner_ids) }

      let_it_be(:runners) { create_list(:ci_runner, 3, :group, groups: [group]) }

      before_all do
        runners.first.update!(tag_list: 'a')
        runners.second.update!(tag_list: 'b')
        runners.third.update!(tag_list: 'b')
      end

      context 'with runner ids' do
        let(:runner_ids) { runners.take(2).map(&:id) }

        it 'returns requested runner namespaces' do
          is_expected.to eq(runners.take(2).flat_map(&:taggings))
        end
      end

      context 'with runners' do
        let(:runner_ids) { runners.first }

        it 'returns requested runner namespaces' do
          is_expected.to eq(runners.first.taggings)
        end
      end
    end
  end
end
