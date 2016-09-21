require 'spec_helper'

describe ProjectLabel, models: true do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }

    context 'validates if title must not exist at group level' do
      let(:group) { create(:group, name: 'gitlab-org') }
      let(:project) { create(:empty_project, group: group) }

      before do
        create(:group_label, group: group, title: 'Bug')
      end

      it 'returns error if title already exists at group level' do
        label = described_class.new(project: project, title: 'Bug')

        label.valid?

        expect(label.errors[:title]).to include 'already exists at group level for gitlab-org. Please choose another one.'
      end

      it 'does not returns error if title does not exist at group level' do
        label = described_class.new(project: project, title: 'Security')

        label.valid?

        expect(label.errors[:title]).to be_empty
      end

      it 'does not returns error if project does not belong to group' do
        another_project = create(:empty_project)
        label = described_class.new(project: another_project, title: 'Bug')

        label.valid?

        expect(label.errors[:title]).to be_empty
      end
    end
  end
end
