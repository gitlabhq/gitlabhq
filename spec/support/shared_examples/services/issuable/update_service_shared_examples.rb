# frozen_string_literal: true

RSpec.shared_examples_for 'issuable update service updating last_edited_at values' do
  context 'when updating the title of the issuable' do
    let(:update_params) { { title: 'updated title' } }

    it 'does not update last_edited values' do
      expect { update_issuable }.to change { issuable.title }.from(issuable.title).to('updated title').and(
        not_change(issuable, :last_edited_at)
      ).and(
        not_change(issuable, :last_edited_by)
      )
    end
  end

  context 'when updating the description of the issuable' do
    let(:update_params) { { description: 'updated description' } }

    it 'updates last_edited values' do
      expect do
        update_issuable
      end.to change { issuable.description }.from(issuable.description).to('updated description').and(
        change { issuable.last_edited_at }
      ).and(
        change { issuable.last_edited_by }
      )
    end
  end
end
