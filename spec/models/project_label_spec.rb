# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectLabel, feature_category: :team_planning do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }

    context 'validates if title must not exist at group level' do
      let(:group) { create(:group, name: 'gitlab-org') }
      let(:project) { create(:project, group: group) }

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
        another_project = create(:project)
        label = described_class.new(project: another_project, title: 'Bug')

        label.valid?

        expect(label.errors[:title]).to be_empty
      end

      it 'does not returns error when title does not change' do
        project_label = create(:label, project: project, name: 'Security')
        create(:group_label, group: group, name: 'Security')
        project_label.description = 'Security related stuff.'

        project_label.valid?

        expect(project_label.errors[:title]).to be_empty
      end
    end

    context 'when attempting to add more than one priority to the project label' do
      it 'returns error' do
        subject.priorities.build
        subject.priorities.build

        subject.valid?

        expect(subject.errors[:priorities]).to include 'Number of permitted priorities exceeded'
      end
    end
  end

  describe '#subject' do
    it 'aliases project to subject' do
      subject = described_class.new(project: build(:project))

      expect(subject.subject).to be(subject.project)
    end
  end

  describe '#to_reference' do
    let(:label) { create(:label) }

    context 'using id' do
      it 'returns a String reference to the object' do
        expect(label.to_reference).to eq "~#{label.id}"
      end
    end

    context 'using name' do
      it 'returns a String reference to the object' do
        expect(label.to_reference(format: :name)).to eq %(~"#{label.name}")
      end

      it 'uses id when name contains double quote' do
        label = create(:label, name: %q("irony"))
        expect(label.to_reference(format: :name)).to eq "~#{label.id}"
      end
    end

    context 'using invalid format' do
      it 'raises error' do
        expect { label.to_reference(format: :invalid) }
          .to raise_error StandardError, /Unknown format/
      end
    end

    context 'cross project reference' do
      let(:project) { create(:project) }

      context 'using name' do
        it 'returns cross reference with label name' do
          expect(label.to_reference(project, format: :name))
            .to eq %(#{label.project.full_path}~"#{label.name}")
        end
      end

      context 'using id' do
        it 'returns cross reference with label id' do
          expect(label.to_reference(project, format: :id))
            .to eq %(#{label.project.full_path}~#{label.id})
        end
      end
    end

    context 'cross groups reference' do
      let(:group) { build_stubbed(:group) }

      context 'using name' do
        it 'returns cross reference with label name' do
          expect(label.to_reference(group, format: :name))
            .to eq %(#{label.project.full_path}~"#{label.name}")
        end
      end

      context 'using id' do
        it 'returns cross reference with label id' do
          expect(label.to_reference(group, format: :id))
            .to eq %(#{label.project.full_path}~#{label.id})
        end
      end
    end
  end

  describe '#preloaded_parent_container' do
    let_it_be(:label) { create(:label) }

    before do
      label.reload # ensure associations are not loaded
    end

    context 'when project is loaded' do
      it 'does not invoke a DB query' do
        label.project

        count = ActiveRecord::QueryRecorder.new { label.preloaded_parent_container }.count
        expect(count).to eq(0)
        expect(label.preloaded_parent_container).to eq(label.project)
      end
    end

    context 'when parent_container is loaded' do
      it 'does not invoke a DB query' do
        label.parent_container

        count = ActiveRecord::QueryRecorder.new { label.preloaded_parent_container }.count
        expect(count).to eq(0)
        expect(label.preloaded_parent_container).to eq(label.parent_container)
      end
    end

    context 'when none of them are loaded' do
      it 'invokes a DB query' do
        count = ActiveRecord::QueryRecorder.new { label.preloaded_parent_container }.count
        expect(count).to eq(1)
      end
    end
  end
end
