# frozen_string_literal: true

RSpec.shared_examples 'copy or reset relative position' do
  before do
    # ensure we have a relative position and it is known
    old_issue.update!(relative_position: 1000)
  end

  context 'when moved to a project within same group hierarchy' do
    it 'does not reset the relative_position' do
      expect(subject.relative_position).to eq(1000)
    end
  end

  context 'when moved to a project in a different group hierarchy' do
    let_it_be(:new_project) { create(:project, group: create(:group)) }

    it 'does reset the relative_position' do
      expect(subject.relative_position).to be_nil
    end
  end
end
