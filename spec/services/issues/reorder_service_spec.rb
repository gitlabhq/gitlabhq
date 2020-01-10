# frozen_string_literal: true

require 'spec_helper'

describe Issues::ReorderService do
  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:group)   { create(:group) }

  shared_examples 'issues reorder service' do
    context 'when reordering issues' do
      it 'returns false with no params' do
        expect(service({}).execute(issue1)).to be_falsey
      end

      it 'returns false with both invalid params' do
        params = { move_after_id: nil, move_before_id: 1 }

        expect(service(params).execute(issue1)).to be_falsey
      end

      it 'sorts issues' do
        params = { move_after_id: issue2.id, move_before_id: issue3.id }

        service(params).execute(issue1)

        expect(issue1.relative_position)
          .to be_between(issue2.relative_position, issue3.relative_position)
      end
    end
  end

  describe '#execute' do
    let(:issue1) { create(:issue, project: project, relative_position: 10) }
    let(:issue2) { create(:issue, project: project, relative_position: 20) }
    let(:issue3) { create(:issue, project: project, relative_position: 30) }

    context 'when ordering issues in a project' do
      let(:parent) { project }

      before do
        parent.add_developer(user)
      end

      it_behaves_like 'issues reorder service'
    end

    context 'when ordering issues in a group' do
      let(:project) { create(:project, namespace: group) }

      before do
        group.add_developer(user)
      end

      it_behaves_like 'issues reorder service'

      context 'when ordering in a group issue list' do
        let(:params) { { move_after_id: issue2.id, move_before_id: issue3.id, group_full_path: group.full_path } }

        subject { service(params) }

        it 'sends the board_group_id parameter' do
          match_params = { move_between_ids: [issue2.id, issue3.id], board_group_id: group.id }

          expect(Issues::UpdateService)
            .to receive(:new).with(project, user, match_params)
            .and_return(double(execute: build(:issue)))

          subject.execute(issue1)
        end

        it 'sorts issues' do
          project2 = create(:project, namespace: group)
          issue4   = create(:issue, project: project2)

          subject.execute(issue4)

          expect(issue4.relative_position)
            .to be_between(issue2.relative_position, issue3.relative_position)
        end
      end
    end
  end

  def service(params)
    described_class.new(project, user, params)
  end
end
