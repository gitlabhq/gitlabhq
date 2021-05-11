# frozen_string_literal: true

RSpec.shared_examples 'boards recent visit' do
  let_it_be(:user) { create(:user) }

  describe '#visited' do
    it 'creates a visit if one does not exists' do
      expect { described_class.visited!(user, board) }.to change(described_class, :count).by(1)
    end

    shared_examples 'was visited previously' do
      let_it_be(:visit) do
        create(visit_relation,
          board_parent_relation => board_parent,
          board_relation => board,
          user: user,
          updated_at: 7.days.ago
        )
      end

      it 'updates the timestamp' do
        freeze_time do
          described_class.visited!(user, board)

          expect(described_class.count).to eq 1
          expect(described_class.first.updated_at).to be_like_time(Time.zone.now)
        end
      end
    end

    it_behaves_like 'was visited previously'

    context 'when we try to create a visit that is not unique' do
      before do
        expect(described_class).to receive(:find_or_create_by).and_raise(ActiveRecord::RecordNotUnique, 'record not unique')
        expect(described_class).to receive(:find_or_create_by).and_return(visit)
      end

      it_behaves_like 'was visited previously'
    end
  end

  describe '#latest' do
    def create_visit(time)
      create(visit_relation, board_parent_relation => board_parent, user: user, updated_at: time)
    end

    it 'returns the most recent visited' do
      create_visit(7.days.ago)
      create_visit(5.days.ago)
      recent = create_visit(1.day.ago)

      expect(described_class.latest(user, board_parent)).to eq recent
    end

    it 'returns last 3 visited boards' do
      create_visit(7.days.ago)
      visit1 = create_visit(3.days.ago)
      visit2 = create_visit(2.days.ago)
      visit3 = create_visit(5.days.ago)

      expect(described_class.latest(user, board_parent, count: 3)).to eq([visit2, visit1, visit3])
    end
  end
end
