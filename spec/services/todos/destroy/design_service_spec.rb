# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::Destroy::DesignService, feature_category: :design_management do
  let_it_be(:user)     { create(:user) }
  let_it_be(:user_2)   { create(:user) }
  let_it_be(:design)   { create(:design) }
  let_it_be(:design_2) { create(:design) }
  let_it_be(:design_3) { create(:design) }

  let_it_be(:create_action)   { create(:design_action, design: design) }
  let_it_be(:create_action_2) { create(:design_action, design: design_2) }

  describe '#execute' do
    before do
      create(:todo, user: user, target: design)
      create(:todo, user: user_2, target: design)
      create(:todo, user: user, target: design_2)
      create(:todo, user: user, target: design_3)
    end

    subject { described_class.new([design.id, design_2.id, design_3.id]).execute }

    context 'when the design has been archived' do
      let_it_be(:archive_action) { create(:design_action, design: design, event: :deletion) }
      let_it_be(:archive_action_2) { create(:design_action, design: design_3, event: :deletion) }

      it 'removes todos for that design' do
        expect { subject }.to change { Todo.count }.from(4).to(1)
      end
    end

    context 'when no design has been archived' do
      it 'does not remove any todos' do
        expect { subject }.not_to change { Todo.count }.from(4)
      end
    end
  end
end
