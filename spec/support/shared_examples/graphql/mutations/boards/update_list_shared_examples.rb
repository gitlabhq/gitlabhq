# frozen_string_literal: true

RSpec.shared_examples 'update board list mutation' do
  describe '#resolve' do
    let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }
    let(:list_update_params) { { position: 1, collapsed: true } }

    subject { mutation.resolve(list: list, **list_update_params) }

    before_all do
      group.add_reporter(reporter)
      group.add_guest(guest)
      list.update_preferences_for(reporter, collapsed: false)
    end

    context 'with permission to admin board lists' do
      let(:current_user) { reporter }

      it 'updates the list position and collapsed state as expected' do
        subject

        reloaded_list = list.reload
        expect(reloaded_list.position).to eq(1)
        expect(reloaded_list.collapsed?(current_user)).to eq(true)
      end
    end

    context 'with permission to read board lists' do
      let(:current_user) { guest }

      it 'updates the list collapsed state but not the list position' do
        subject

        reloaded_list = list.reload
        expect(reloaded_list.position).to eq(0)
        expect(reloaded_list.collapsed?(current_user)).to eq(true)
      end
    end

    context 'without permission to read board lists' do
      let(:current_user) { create(:user) }

      it 'raises Resource Not Found error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
