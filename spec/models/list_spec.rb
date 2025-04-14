# frozen_string_literal: true

require 'spec_helper'

RSpec.describe List do
  it_behaves_like 'having unique enum values'
  it_behaves_like 'boards listable model', :list
  it_behaves_like 'list_preferences_for user', :list, :list_id

  describe 'relationships' do
    it { is_expected.to belong_to(:board) }
    it { is_expected.to belong_to(:label) }
  end

  describe 'validations' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:group_board) { create(:board, group: group) }
    let_it_be(:project_board) { create(:board, project: project) }

    it { is_expected.to validate_presence_of(:board) }
    it { is_expected.to validate_presence_of(:label) }
    it { is_expected.to validate_presence_of(:list_type) }

    describe 'group presence' do
      it { is_expected.to validate_presence_of(:group) }

      context 'when project is present' do
        subject { described_class.new(board: project_board) }

        it { is_expected.not_to validate_presence_of(:group) }
      end
    end

    describe 'project presence' do
      it { is_expected.to validate_presence_of(:project) }

      context 'when group is present' do
        subject { described_class.new(board: group_board) }

        it { is_expected.not_to validate_presence_of(:project) }
      end
    end

    describe 'group and project mutually exclusive' do
      context 'when project is present' do
        it 'validates that project and group are mutually exclusive' do
          expect(described_class.new(board: project_board)).to validate_absence_of(:group)
            .with_message(_("can't be specified if a project was already provided"))
        end
      end

      context 'when project is not present' do
        it { is_expected.not_to validate_absence_of(:group) }
      end
    end
  end
end
