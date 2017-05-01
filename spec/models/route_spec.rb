require 'spec_helper'

describe Route, models: true do
  let!(:group) { create(:group, path: 'git_lab', name: 'git_lab') }
  let!(:route) { group.route }

  describe 'relationships' do
    it { is_expected.to belong_to(:source) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_uniqueness_of(:path) }
  end

  describe '.inside_path' do
    let!(:nested_group) { create(:group, path: 'test', name: 'test', parent: group) }
    let!(:deep_nested_group) { create(:group, path: 'foo', name: 'foo', parent: nested_group) }
    let!(:another_group) { create(:group, path: 'other') }
    let!(:similar_group) { create(:group, path: 'gitllab') }
    let!(:another_group_nested) { create(:group, path: 'another', name: 'another', parent: similar_group) }

    it 'returns correct routes' do
      expect(Route.inside_path('git_lab')).to match_array([nested_group.route, deep_nested_group.route])
    end
  end

  describe '.direct_descendant_routes' do
    let!(:nested_group) { create(:group, path: 'test', name: 'test', parent: group) }
    let!(:deep_nested_group) { create(:group, path: 'foo', name: 'foo', parent: nested_group) }
    let!(:another_group) { create(:group, path: 'other') }
    let!(:similar_group) { create(:group, path: 'gitllab') }
    let!(:another_group_nested) { create(:group, path: 'another', name: 'another', parent: similar_group) }

    it 'returns correct routes' do
      expect(Route.direct_descendant_routes('git_lab')).to match_array([nested_group.route])
      expect(Route.direct_descendant_routes('git_lab/test')).to match_array([deep_nested_group.route])
    end
  end

  describe '#rename_direct_descendant_routes' do
    let!(:nested_group) { create(:group, path: 'test', name: 'test', parent: group) }
    let!(:deep_nested_group) { create(:group, path: 'foo', name: 'foo', parent: nested_group) }
    let!(:similar_group) { create(:group, path: 'gitlab-org', name: 'gitlab-org') }
    let!(:another_group) { create(:group, path: 'gittlab', name: 'gitllab') }
    let!(:another_group_nested) { create(:group, path: 'git_lab', name: 'git_lab', parent: another_group) }

    context 'path update' do
      context 'when route name is set' do
        before { route.update_attributes(path: 'bar') }

        it "updates children routes with new path" do
          expect(described_class.exists?(path: 'bar')).to be_truthy
          expect(described_class.exists?(path: 'bar/test')).to be_truthy
          expect(described_class.exists?(path: 'bar/test/foo')).to be_truthy
          expect(described_class.exists?(path: 'gitlab-org')).to be_truthy
          expect(described_class.exists?(path: 'gittlab')).to be_truthy
          expect(described_class.exists?(path: 'gittlab/git_lab')).to be_truthy
        end
      end

      context 'when route name is nil' do
        before do
          route.update_column(:name, nil)
        end

        it "does not fail" do
          expect(route.update_attributes(path: 'bar')).to be_truthy
        end
      end
    end

    context 'name update' do
      it "updates children routes with new path" do
        route.update_attributes(name: 'bar')

        expect(described_class.exists?(name: 'bar')).to be_truthy
        expect(described_class.exists?(name: 'bar / test')).to be_truthy
        expect(described_class.exists?(name: 'bar / test / foo')).to be_truthy
        expect(described_class.exists?(name: 'gitlab-org')).to be_truthy
      end

      it 'handles a rename from nil' do
        # Note: using `update_columns` to skip all validation and callbacks
        route.update_columns(name: nil)

        expect { route.update_attributes(name: 'bar') }
          .to change { route.name }.from(nil).to('bar')
      end
    end
  end

  describe '#create_redirect_if_path_changed' do
    context 'if the path changed' do
      it 'creates a RedirectRoute for the old path' do
        route.path = 'new-path'
        route.save!
        redirect = route.source.redirect_routes.first
        expect(redirect.path).to eq('git_lab')
      end
    end

    context 'if the path did not change' do
      it 'does not create a RedirectRoute' do
        route.updated_at = Time.zone.now.utc
        route.save!
        expect(route.source.redirect_routes).to be_empty
      end
    end
  end
end
