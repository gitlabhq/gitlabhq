# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Route do
  include LooseForeignKeysHelper

  let(:group) { create(:group, path: 'git_lab', name: 'git_lab') }
  let(:route) { group.route }

  describe 'relationships' do
    it { is_expected.to belong_to(:source) }
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    before do
      expect(route).to be_persisted
    end

    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_uniqueness_of(:path).case_insensitive }
  end

  describe 'callbacks' do
    context 'after update' do
      it 'calls #create_redirect_for_old_path' do
        expect(route).to receive(:create_redirect_for_old_path)
        route.update!(path: 'foo')
      end

      it 'calls #delete_conflicting_redirects' do
        expect(route).to receive(:delete_conflicting_redirects)
        route.update!(path: 'foo')
      end
    end

    context 'after create' do
      it 'calls #delete_conflicting_redirects' do
        route.destroy!
        new_route = described_class.new(source: group, path: group.path, namespace: group)
        expect(new_route).to receive(:delete_conflicting_redirects)
        new_route.save!
      end
    end
  end

  describe '.inside_path' do
    let!(:nested_group) { create(:group, path: 'test', name: 'test', parent: group) }
    let!(:deep_nested_group) { create(:group, path: 'foo', name: 'foo', parent: nested_group) }
    let!(:another_group) { create(:group, path: 'other') }
    let!(:similar_group) { create(:group, path: 'gitllab') }
    let!(:another_group_nested) { create(:group, path: 'another', name: 'another', parent: similar_group) }

    it 'returns correct routes' do
      expect(described_class.inside_path('git_lab')).to match_array([nested_group.route, deep_nested_group.route])
    end
  end

  describe '.for_routable_type' do
    let_it_be(:group) { create(:group, path: 'git_lab', name: 'git_lab') }
    let_it_be(:nested_group) { create(:group, path: 'foo', name: 'foo', parent: group) }
    let_it_be(:project) { create(:project, path: 'other-project') }

    it 'returns correct routes' do
      expect(described_class.for_routable_type(Project.name)).to match_array([project.route])
    end
  end

  describe '.by_paths' do
    let!(:nested_group) { create(:group, path: 'foo', name: 'foo', parent: group) }
    let!(:project) { create(:project, path: 'other-project', namespace: group) }

    it 'returns correct routes' do
      expect(described_class.by_paths(%w[git_lab/foo git_lab/other-project])).to match_array(
        [nested_group.route, project.route]
      )
    end

    context 'with all mismatched paths' do
      it 'returns no routes' do
        expect(described_class.by_paths(%w[foo other-project])).to be_empty
      end
    end

    context 'with some mismatched paths' do
      it 'returns no routes' do
        expect(described_class.by_paths(%w[foo git_lab/other-project])).to match_array([project.route])
      end
    end
  end

  describe '#rename_descendants' do
    let!(:nested_group) { create(:group, path: 'test', name: 'test', parent: group) }
    let!(:deep_nested_group) { create(:group, path: 'foo', name: 'foo', parent: nested_group) }
    let!(:similar_group) { create(:group, path: 'gitlab-org', name: 'gitlab-org') }
    let!(:another_group) { create(:group, path: 'gittlab', name: 'gitllab') }
    let!(:another_group_nested) { create(:group, path: 'git_lab', name: 'git_lab', parent: another_group) }

    context 'path update' do
      context 'when route name is set' do
        before do
          route.update!(path: 'bar')
        end

        it 'updates children routes with new path' do
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
          expect(route.update(path: 'bar')).to be_truthy
        end
      end

      context 'when conflicting redirects exist' do
        let(:route) { create(:project).route }
        let!(:conflicting_redirect1) { route.create_redirect('bar/test') }
        let!(:conflicting_redirect2) { route.create_redirect('bar/test/foo') }
        let!(:conflicting_redirect3) { route.create_redirect('gitlab-org') }

        it 'deletes the conflicting redirects' do
          route.update!(path: 'bar')

          expect(RedirectRoute.exists?(path: 'bar/test')).to be_falsey
          expect(RedirectRoute.exists?(path: 'bar/test/foo')).to be_falsey
          expect(RedirectRoute.exists?(path: 'gitlab-org')).to be_truthy
        end
      end
    end

    context 'name update' do
      it 'updates children routes with new path' do
        route.update!(name: 'bar')

        expect(described_class.exists?(name: 'bar')).to be_truthy
        expect(described_class.exists?(name: 'bar / test')).to be_truthy
        expect(described_class.exists?(name: 'bar / test / foo')).to be_truthy
        expect(described_class.exists?(name: 'gitlab-org')).to be_truthy
      end

      it 'handles a rename from nil' do
        # Note: using `update_columns` to skip all validation and callbacks
        route.update_columns(name: nil)

        expect { route.update!(name: 'bar') }
          .to change { route.name }.from(nil).to('bar')
      end
    end
  end

  describe '#create_redirect_for_old_path' do
    context 'if the path changed' do
      it 'creates a RedirectRoute for the old path' do
        redirect_scope = route.source.redirect_routes.where(path: 'git_lab')
        expect(redirect_scope.exists?).to be_falsey
        route.path = 'new-path'
        route.save!
        expect(redirect_scope.exists?).to be_truthy
      end
    end
  end

  describe '#create_redirect' do
    it 'creates a RedirectRoute with the same source' do
      redirect_route = route.create_redirect('foo')
      expect(redirect_route).to be_a(RedirectRoute)
      expect(redirect_route).to be_persisted
      expect(redirect_route.source).to eq(route.source)
      expect(redirect_route.path).to eq('foo')
    end

    context 'when the source is a Project' do
      it 'creates a RedirectRoute' do
        project = create(:project)
        route = project.route
        redirect_route = route.create_redirect('foo')
        expect(redirect_route).not_to be_nil
      end
    end

    context 'when the source is not a project' do
      it 'creates a RedirectRoute' do
        redirect_route = route.create_redirect('foo')
        expect(redirect_route).not_to be_nil
      end
    end
  end

  describe '#delete_conflicting_redirects' do
    let(:route) { create(:project).route }

    it 'deletes the redirect' do
      route.create_redirect("#{route.path}/foo")

      expect do
        route.delete_conflicting_redirects
      end.to change { RedirectRoute.count }.by(-1)
    end

    context 'when a redirect route with the same path exists' do
      context 'when the redirect route has matching case' do
        let(:route) { create(:project).route }
        let!(:redirect1) { route.create_redirect(route.path) }

        it 'deletes the redirect' do
          expect do
            route.delete_conflicting_redirects
          end.to change { RedirectRoute.count }.by(-1)
        end

        context 'when redirect routes with paths descending from the route path exists' do
          let!(:redirect2) { route.create_redirect("#{route.path}/foo") }
          let!(:redirect3) { route.create_redirect("#{route.path}/foo/bar") }
          let!(:redirect4) { route.create_redirect("#{route.path}/baz/quz") }
          let!(:other_redirect) { route.create_redirect("other") }

          it 'deletes all redirects with paths that descend from the route path' do
            expect do
              route.delete_conflicting_redirects
            end.to change { RedirectRoute.count }.by(-4)
          end
        end
      end

      context 'when the redirect route is differently cased' do
        let(:route) { create(:project).route }
        let!(:redirect1) { route.create_redirect(route.path.upcase) }

        it 'deletes the redirect' do
          expect do
            route.delete_conflicting_redirects
          end.to change { RedirectRoute.count }.by(-1)
        end
      end
    end
  end

  describe '#conflicting_redirects' do
    let(:route) { create(:project).route }

    it 'returns an ActiveRecord::Relation' do
      expect(route.conflicting_redirects).to be_an(ActiveRecord::Relation)
    end

    it 'returns the redirect routes' do
      redirect1 = route.create_redirect("#{route.path}/foo")
      redirect2 = route.create_redirect("#{route.path}/foo/bar")
      redirect3 = route.create_redirect("#{route.path}/baz/quz")

      expect(route.conflicting_redirects).to match_array([redirect1, redirect2, redirect3])
    end

    context 'when a redirect route with the same path exists' do
      let(:route) { create(:project).route }

      context 'when the redirect route has matching case' do
        let!(:redirect1) { route.create_redirect(route.path) }

        it 'returns the redirect route' do
          expect(route.conflicting_redirects).to match_array([redirect1])
        end

        context 'when redirect routes with paths descending from the route path exists' do
          let!(:redirect2) { route.create_redirect("#{route.path}/foo") }
          let!(:redirect3) { route.create_redirect("#{route.path}/foo/bar") }
          let!(:redirect4) { route.create_redirect("#{route.path}/baz/quz") }
          let!(:other_redirect) { route.create_redirect("other") }

          it 'returns the redirect routes' do
            expect(route.conflicting_redirects).to match_array([redirect1, redirect2, redirect3, redirect4])
          end
        end
      end

      context 'when the redirect route is differently cased' do
        let!(:redirect1) { route.create_redirect(route.path.upcase) }

        it 'returns the redirect route' do
          expect(route.conflicting_redirects).to match_array([redirect1])
        end
      end
    end
  end

  describe 'conflicting routes validation' do
    context 'when there is a conflicting route' do
      let!(:conflicting_group) { create(:group, path: 'foo') }

      before do
        route.path = conflicting_group.route.path
      end

      context 'when deleting the conflicting route' do
        let!(:offending_route) { conflicting_group.route }

        it 'does not delete the original route' do
          # before deleting the route, check its there
          expect(described_class.where(path: offending_route.path).count).to eq(1)

          expect do
            Group.delete(conflicting_group) # delete group with conflicting route
            process_loose_foreign_key_deletions(record: conflicting_group)
          end.to change { described_class.count }.by(-1)

          # check the conflicting route is gone
          expect(described_class.where(path: offending_route.path).count).to eq(0)
          expect(route.path).to eq(offending_route.path)
          expect(route.valid?).to be_truthy
        end
      end

      it 'fails validation' do
        expect(route.valid?).to be_falsey
      end
    end

    context 'when there are no conflicting routes' do
      it 'passes validation' do
        expect(route.valid?).to be_truthy
      end
    end
  end

  context 'with loose foreign key on routes.namespace_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:namespace) }
      let_it_be(:model) { parent.route }
    end
  end
end
