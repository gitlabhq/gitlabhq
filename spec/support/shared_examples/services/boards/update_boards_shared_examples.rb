# frozen_string_literal: true

RSpec.shared_examples 'board update service' do
  subject(:service) { described_class.new(board.resource_parent, user, all_params) }

  it 'updates the board with valid params' do
    result = described_class.new(group, user, name: 'Engineering').execute(board)

    expect(result).to eq(true)
    expect(board.reload.name).to eq('Engineering')
  end

  it 'does not update the board with invalid params' do
    orig_name = board.name

    result = described_class.new(group, user, name: nil).execute(board)

    expect(result).to eq(false)
    expect(board.reload.name).to eq(orig_name)
  end

  context 'with scoped_issue_board available' do
    before do
      stub_licensed_features(scoped_issue_board: true)
    end

    context 'user is member of the board parent' do
      before do
        board.resource_parent.add_reporter(user)
      end

      it 'updates the configuration params when scoped issue board is enabled' do
        service.execute(board)

        labels = updated_scoped_params.delete(:labels)
        expect(board.reload).to have_attributes(updated_scoped_params)
        expect(board.labels).to match_array(labels)
      end
    end

    context 'when labels param is used' do
      let(:params) { { labels: [label.name, parent_label.name, 'new label'].join(',') } }

      subject(:service) { described_class.new(board.resource_parent, user, params) }

      context 'when user can create new labels' do
        before do
          board.resource_parent.add_reporter(user)
        end

        it 'adds labels to the board' do
          service.execute(board)

          expect(board.reload.labels.map(&:name)).to match_array([label.name, parent_label.name, 'new label'])
        end
      end

      context 'when user can not create new labels' do
        before do
          board.resource_parent.add_guest(user)
        end

        it 'adds only existing labels to the board' do
          service.execute(board)

          expect(board.reload.labels.map(&:name)).to match_array([label.name, parent_label.name])
        end
      end
    end
  end

  context 'without scoped_issue_board available' do
    before do
      stub_licensed_features(scoped_issue_board: false)
    end

    it 'filters unpermitted params when scoped issue board is not enabled' do
      service.execute(board)

      expect(board.reload).to have_attributes(updated_without_scoped_params)
    end
  end
end
