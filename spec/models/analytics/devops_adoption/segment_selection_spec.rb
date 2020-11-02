# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::DevopsAdoption::SegmentSelection, type: :model do
  subject { build(:devops_adoption_segment_selection, :project) }

  describe 'validation' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project) }

    it { is_expected.to validate_presence_of(:segment) }

    context do
      subject { create(:devops_adoption_segment_selection, :project, project: project) }

      it { is_expected.to validate_uniqueness_of(:project_id).scoped_to(:segment_id) }
    end

    context do
      subject { create(:devops_adoption_segment_selection, :group, group: group) }

      it { is_expected.to validate_uniqueness_of(:group_id).scoped_to(:segment_id) }
    end

    it 'project is required' do
      selection = build(:devops_adoption_segment_selection, project: nil, group: nil)

      selection.validate

      expect(selection.errors).to have_key(:project)
    end

    it 'project is not required when a group is given' do
      selection = build(:devops_adoption_segment_selection, :group, group: group)

      expect(selection).to be_valid
    end

    it 'does not allow group to be set when project is present' do
      selection = build(:devops_adoption_segment_selection)

      selection.group = group
      selection.project = project

      selection.validate

      expect(selection.errors[:group]).to eq([s_('DevopsAdoptionSegmentSelection|The selection cannot be configured for a project and for a group at the same time')])
    end

    context 'limit the number of segment selections' do
      let_it_be(:segment) { create(:devops_adoption_segment) }

      subject { build(:devops_adoption_segment_selection, segment: segment, project: project) }

      before do
        create(:devops_adoption_segment_selection, :project, segment: segment)

        stub_const("#{described_class}::ALLOWED_SELECTIONS_PER_SEGMENT", 1)
      end

      it 'shows validation error' do
        subject.validate

        expect(subject.errors[:segment]).to eq([s_('DevopsAdoptionSegment|The maximum number of selections has been reached')])
      end
    end
  end
end
