# frozen_string_literal: true

RSpec.shared_examples 'group archiving abilities' do
  let(:group) { create(:group, :public) }
  let(:policy) { described_class.new(current_user, group) }
  let(:current_user) { owner }

  shared_examples 'prevents archived abilities' do
    it 'prevents abilities defined in archived_abilities' do
      archived_abilities.each do |ability|
        expect(policy).not_to be_allowed(ability)
      end
    end
  end

  shared_examples 'prevents destroy actions' do
    it 'prevents destroy actions on archived features' do
      destroy_abilities.each do |feature|
        expect(policy).not_to be_allowed(feature)
      end
    end
  end

  shared_examples 'allows destroy actions' do
    it 'allows destroy actions on archived features' do
      destroy_abilities.each do |feature|
        expect(policy).to be_allowed(feature) if policy.respond_to?(:"#{feature}")
      end
    end
  end

  shared_examples 'archived but not marked for deletion' do
    it_behaves_like 'prevents archived abilities'
    it_behaves_like 'prevents destroy actions'
  end

  shared_examples 'archived and marked for deletion' do
    it_behaves_like 'prevents archived abilities'
    it_behaves_like 'allows destroy actions'
  end

  context 'when group is archived but not marked for deletion' do
    before do
      group.archive
    end

    it_behaves_like 'archived but not marked for deletion'
  end

  context 'when group is archived and marked for deletion' do
    before do
      group.archive
      group.namespace_details.update!(deleted_at: Time.current)
    end

    it_behaves_like 'archived and marked for deletion'
  end

  context 'when group ancestor is archived' do
    let(:group) { create(:group, :nested) }

    before do
      group.parent.archive
    end

    it_behaves_like 'archived but not marked for deletion'
  end

  context 'when group ancestor is marked for deletion' do
    let(:group) { create(:group, :nested) }

    before do
      group.parent.archive
      group.parent.namespace_details.update!(deleted_at: Time.current)
    end

    it_behaves_like 'archived and marked for deletion'
  end
end
