# frozen_string_literal: true

RSpec.shared_examples 'correct release milestone order' do
  let_it_be_with_reload(:milestone_1) { create(:milestone, project: project) }
  let_it_be_with_reload(:milestone_2) { create(:milestone, project: project) }

  shared_examples 'correct sort order' do
    it 'sorts milestonee_1 before milestone_2' do
      freeze_time do
        expect(actual_milestone_title_order).to eq([milestone_1.title, milestone_2.title])
      end
    end
  end

  context 'due_date' do
    before do
      milestone_1.update!(due_date: Time.zone.now, start_date: 1.day.ago, title: 'z')
      milestone_2.update!(due_date: 1.day.from_now, start_date: 2.days.ago, title: 'a')
    end

    context 'when both milestones have a due_date' do
      it_behaves_like 'correct sort order'
    end

    context 'when one milestone does not have a due_date' do
      before do
        milestone_2.update!(due_date: nil)
      end

      it_behaves_like 'correct sort order'
    end
  end

  context 'start_date' do
    before do
      milestone_1.update!(due_date: 1.day.from_now, start_date: 1.day.ago, title: 'z')
      milestone_2.update!(due_date: 1.day.from_now, start_date: milestone_2_start_date, title: 'a')
    end

    context 'when both milestones have a start_date' do
      let(:milestone_2_start_date) { Time.zone.now }

      it_behaves_like 'correct sort order'
    end

    context 'when one milestone does not have a start_date' do
      let(:milestone_2_start_date) { nil }

      it_behaves_like 'correct sort order'
    end
  end

  context 'title' do
    before do
      milestone_1.update!(due_date: 1.day.from_now, start_date: Time.zone.now, title: 'a')
      milestone_2.update!(due_date: 1.day.from_now, start_date: Time.zone.now, title: 'z')
    end

    it_behaves_like 'correct sort order'
  end
end
