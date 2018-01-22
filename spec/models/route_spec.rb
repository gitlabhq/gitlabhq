require 'spec_helper'

describe Route do
  let(:group) { create(:group, path: 'git_lab', name: 'git_lab') }
  let(:route) { group.route }

  describe 'relationships' do
    it { is_expected.to belong_to(:source) }
  end

  describe 'validations' do
    before do
      expect(route).to be_persisted
    end

    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_uniqueness_of(:path).case_insensitive }

    describe '#ensure_permanent_paths' do
      context 'when the route is not yet persisted' do
        let(:new_route) { described_class.new(path: 'foo', source: build(:group)) }

        context 'when permanent conflicting redirects exist' do
          it 'is invalid' do
            redirect = build(:redirect_route, :permanent, path: 'foo/bar/baz')
            redirect.save!(validate: false)

            expect(new_route.valid?).to be_falsey
            expect(new_route.errors.first[1]).to eq('foo has been taken before. Please use another one.')
          end
        end

        context 'when no permanent conflicting redirects exist' do
          it 'is valid' do
            expect(new_route.valid?).to be_truthy
          end
        end
      end

      context 'when path has changed' do
        before do
          route.path = 'foo'
        end

        context 'when permanent conflicting redirects exist' do
          it 'is invalid' do
            redirect = build(:redirect_route, :permanent, path: 'foo')
            redirect.save!(validate: false)

            expect(route.valid?).to be_falsey
            expect(route.errors.first[1]).to eq('foo has been taken before. Please use another one.')
          end
        end

        context 'when no permanent conflicting redirects exist' do
          it 'is valid' do
            expect(route.valid?).to be_truthy
          end
        end
      end

      context 'when path has not changed' do
        context 'when permanent conflicting redirects exist' do
          it 'is valid' do
            redirect = build(:redirect_route, :permanent, path: 'git_lab/foo/bar')
            redirect.save!(validate: false)

            expect(route.valid?).to be_truthy
          end
        end
        context 'when no permanent conflicting redirects exist' do
          it 'is valid' do
            expect(route.valid?).to be_truthy
          end
        end
      end

      context 'when reclaiming an old path' do
        let(:group_foo) { create(:group, name: 'foo', path: 'foo') }
        let!(:project_baz) { create(:project, :repository, name: 'baz', path: 'baz', namespace: group_foo) }

        before do
          group_foo.path = 'baz'
          group_foo.save

          group_foo.path = 'foo'
          TestEnv.clean_test_path
        end

        it 'should be valid' do
          expect(group_foo.valid?).to be_truthy
        end

        it 'should be saved' do
          expect(group_foo.save).to be_truthy
        end

        it 'should delete old redirect routes for the group and project' do
          group_foo.save

          expect(group_foo.redirect_routes.permanent.find_by(path: 'foo')).to be_nil
          expect(group_foo.redirect_routes.count).to eq(1)
          expect(group_foo.redirect_routes.permanent.first.path).to eq('baz')

          expect(project_baz.redirect_routes.permanent.find_by(path: 'foo/baz')).to be_nil
          expect(project_baz.redirect_routes.count).to eq(1)
          expect(project_baz.redirect_routes.permanent.first.path).to eq('baz/baz')
        end
      end
    end
  end

  describe 'callbacks' do
    context 'before validation' do
      it 'calls #delete_conflicting_orphaned_routes' do
        expect(route).to receive(:delete_conflicting_orphaned_routes)
        route.valid?
      end
    end

    context 'after update' do
      it 'calls #update_redirect_routes' do
        expect(route).to receive(:create_redirect_for_old_path)
        route.update_attributes(path: 'foo')
      end

      it 'calls #rename_descendants' do
        expect(route).to receive(:rename_descendants)
        route.update_attributes(path: 'foo')
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

  describe '#rename_descendants' do
    let!(:nested_group) { create(:group, path: 'test', name: 'test', parent: group) }
    let!(:deep_nested_group) { create(:group, path: 'foo', name: 'foo', parent: nested_group) }
    let!(:similar_group) { create(:group, path: 'gitlab-org', name: 'gitlab-org') }
    let!(:another_group) { create(:group, path: 'gittlab', name: 'gitllab') }
    let!(:another_group_nested) { create(:group, path: 'git_lab', name: 'git_lab', parent: another_group) }
    let!(:foo_project) { create(:project, path: 'foo', name: 'test', namespace: group) }

    context 'path update' do
      context 'when route name is set' do
        before do
          route.update_attributes(path: 'bar')
        end

        it 'updates children routes with new path' do
          expect(described_class.exists?(path: 'bar')).to be_truthy
          expect(described_class.exists?(path: 'bar/test')).to be_truthy
          expect(described_class.exists?(path: 'bar/test/foo')).to be_truthy
          expect(described_class.exists?(path: 'gitlab-org')).to be_truthy
          expect(described_class.exists?(path: 'gittlab')).to be_truthy
          expect(described_class.exists?(path: 'gittlab/git_lab')).to be_truthy
        end

        it 'creates redirects for children' do
          expect(nested_group.redirect_routes.permanent.count).to eq(1)
          expect(deep_nested_group.redirect_routes.permanent.count).to eq(1)
          expect(foo_project.redirect_routes.permanent.count).to eq(1)
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

      context 'when conflicting redirects exist' do
        let(:route) { create(:project).route }
        let!(:conflicting_redirect1) { create(:redirect_route, source: route, path: 'bar/test') }
        let!(:conflicting_redirect2) { create(:redirect_route, source: route, path: 'bar/test/foo') }
        let!(:conflicting_redirect3) { create(:redirect_route, source: route, path: 'gitlab-org') }

        it 'deletes the conflicting redirects' do
          route.update_attributes(path: 'bar')

          expect(RedirectRoute.exists?(path: 'bar/test')).to be_falsey
          expect(RedirectRoute.exists?(path: 'bar/test/foo')).to be_falsey
          expect(RedirectRoute.exists?(path: 'gitlab-org')).to be_truthy
        end
      end
    end

    context 'name update' do
      it 'updates children routes with new path' do
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

  # Redirect route scenarios are included in more detail in spec/support/route_redirects.rb
  describe '#update_redirect_routes' do
    it 'creates a temporary RedirectRoute if the source is a Project' do
      project = create(:project, path: 'foo')
      project.path = 'baz'
      project.save

      expect(project.redirect_routes.count).to eq(1)
      expect(project.redirect_routes.temporary.first.path).to eq("#{project.namespace.name}/foo")
    end

    it 'creates a permanent RedirectRoute if the source is not a Project' do
      group.path = 'foo'
      group.save

      expect(group.redirect_routes.count).to eq(1)
      expect(group.redirect_routes.permanent.first.path).to eq('git_lab')
    end

    context 'with a permanent RedirectRoute with a different path' do
      it 'Creates a new RedirectRoute' do
        create(:redirect_route, source: route, path: "#{route.path}/foo", permanent: true)

        expect do
          group.path = 'baz'
          group.save
        end.to change { RedirectRoute.count }.by(1)
      end
    end

    context 'with a permanent RedirectRoute with the same path' do
      it 'does delete the old redirect' do
        group.path = 'baz'
        group.save

        expect(group.redirect_routes.permanent.count).to eq(1)
        expect(group.redirect_routes.permanent.first.path).to eq('git_lab')

        group.path = 'git_lab'
        group.save

        expect(group.redirect_routes.permanent.count).to eq(1)
        expect(group.redirect_routes.permanent.first.path).to eq('baz')
      end
    end

    context 'with temporary redirect' do
      let(:project) { create(:project) }

      it 'creates temporary redirects for a project' do
        project.path = 'baz'
        project.save

        expect(project.redirect_routes.count).to eq(1)

        project.path = 'bax'
        project.save

        expect(project.redirect_routes.count).to eq(2)
      end
    end
  end

  describe "#conflicting_redirect_exists?" do
    context 'when a conflicting redirect does not exist' do
      let(:project1) { create(:project, path: 'foo') }
      let(:project2) { create(:project, path: 'baz') }

      it 'should be saved' do
        project1.path = 'bar'
        project1.save

        project2.path = 'foo'
        expect(project2.save).to be_truthy
      end
    end
  end

  describe '#delete_conflicting_orphaned_routes' do
    context 'when there is a conflicting route' do
      let!(:conflicting_group) { create(:group, path: 'foo') }

      before do
        route.path = conflicting_group.route.path
      end

      context 'when the route is orphaned' do
        let!(:offending_route) { conflicting_group.route }

        before do
          Group.delete(conflicting_group) # Orphan the route
        end

        it 'deletes the orphaned route' do
          expect do
            route.valid?
          end.to change { described_class.count }.from(2).to(1)
        end

        it 'passes validation, as usual' do
          expect(route.valid?).to be_truthy
        end
      end

      context 'when the route is not orphaned' do
        it 'does not delete the conflicting route' do
          expect do
            route.valid?
          end.not_to change { described_class.count }
        end

        it 'fails validation, as usual' do
          expect(route.valid?).to be_falsey
        end
      end
    end

    context 'when there are no conflicting routes' do
      it 'does not delete any routes' do
        route

        expect do
          route.valid?
        end.not_to change { described_class.count }
      end

      it 'passes validation, as usual' do
        expect(route.valid?).to be_truthy
      end
    end
  end

  include_examples 'route redirects for groups, users and projects', described_class
end
