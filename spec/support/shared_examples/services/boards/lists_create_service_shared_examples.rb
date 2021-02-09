# frozen_string_literal: true

RSpec.shared_examples 'board lists create service' do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    before_all do
      parent.add_developer(user)
    end

    subject(:service) { described_class.new(parent, user, label_id: label.id) }

    context 'when board lists is empty' do
      it 'creates a new list at beginning of the list' do
        response = service.execute(board)

        expect(response.success?).to eq(true)
        expect(response.payload[:list].position).to eq 0
      end
    end

    context 'when board lists has the done list' do
      it 'creates a new list at beginning of the list' do
        response = service.execute(board)

        expect(response.success?).to eq(true)
        expect(response.payload[:list].position).to eq 0
      end
    end

    context 'when board lists has labels lists' do
      it 'creates a new list at end of the lists' do
        create_list(position: 0)
        create_list(position: 1)

        response = service.execute(board)

        expect(response.success?).to eq(true)
        expect(response.payload[:list].position).to eq 2
      end
    end

    context 'when board lists has label and done lists' do
      it 'creates a new list at end of the label lists' do
        list1 = create_list(position: 0)

        list2 = service.execute(board).payload[:list]

        expect(list1.reload.position).to eq 0
        expect(list2.reload.position).to eq 1
      end
    end

    context 'when provided label does not belong to the parent' do
      it 'returns an error' do
        label = create(:label, name: 'in-development')
        service = described_class.new(parent, user, label_id: label.id)

        response = service.execute(board)

        expect(response.success?).to eq(false)
        expect(response.errors).to include('Label not found')
      end
    end

    context 'when backlog param is sent' do
      it 'creates one and only one backlog list' do
        service = described_class.new(parent, user, 'backlog' => true)
        list = service.execute(board).payload[:list]

        expect(list.list_type).to eq('backlog')
        expect(list.position).to be_nil
        expect(list).to be_valid

        another_backlog = service.execute(board).payload[:list]

        expect(another_backlog).to eq list
      end
    end
  end
end
