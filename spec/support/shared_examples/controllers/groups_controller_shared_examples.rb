# frozen_string_literal: true

RSpec.shared_examples 'groups controller with active parameter' do
  let_it_be(:active_group) { create(:group, :public, developers: [user]) }
  let_it_be(:inactive_group) { create(:group, :archived, :public, developers: [user]) }

  let(:params) { {} }

  before do
    get :index, params: params, format: :json
  end

  context 'when true' do
    let(:params) { { active: true } }

    it 'returns active group', :aggregate_failures do
      expect(assigns(:groups)).to include(active_group)
      expect(assigns(:groups)).not_to include(inactive_group)
    end
  end

  context 'when false' do
    let(:params) { { active: false } }

    it 'returns inactive group' do
      expect(assigns(:groups)).to contain_exactly(inactive_group)
    end

    context 'when active group has inactive subgroup' do
      let_it_be(:active_subgroup) { create(:group, parent: active_group) }
      let_it_be(:inactive_subgroup) { create(:group, :archived, parent: active_group) }

      it 'returns inactive subgroup' do
        expect(assigns(:groups)).to contain_exactly(inactive_group, inactive_subgroup)
      end
    end

    context 'when inactive group has active subgroup' do
      let_it_be(:active_subgroup) { create(:group, parent: inactive_group) }

      it 'returns inactive group with subgroup' do
        expect(assigns(:groups)).to contain_exactly(inactive_group, active_subgroup)
      end
    end

    context 'when inactive group has inactive subgroup' do
      let_it_be(:inactive_subgroup) { create(:group, :archived, parent: inactive_group) }

      it 'returns inactive group with subgroup' do
        expect(assigns(:groups)).to contain_exactly(inactive_group, inactive_subgroup)
      end
    end

    context "when groups has lower-level inactive subgroup" do
      let_it_be(:inactive_subgroup) { create(:group, :archived, parent: active_group) }
      let_it_be(:inactive_subsubgroup) { create(:group, :archived, parent: inactive_subgroup) }

      let(:params) { { active: false, filter: inactive_subsubgroup.name } }

      it 'returns inactive subgroup with its inactive parents' do
        expect(json_response.first['id']).to eq(inactive_subgroup.id)
        expect(json_response.first['children'].first['id']).to eq(inactive_subsubgroup.id)
      end
    end
  end
end
