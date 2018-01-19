shared_examples 'route redirects for groups, users and projects' do
  before do
    TestEnv.clean_test_path
  end

  context 'when a Group with projects is renamed' do
    let!(:group_foo) { create(:group, name: 'foo', path: 'foo') }
    let!(:project) { create(:project, path: 'bar', namespace: group_foo) }

    it 'should create the appropriate redirect routes' do
      group_foo.path = 'foot'
      group_foo.save
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('foo')
      expect(project.redirect_routes.temporary.count).to eq(1)
      expect(project.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar'])

      group_foo.path = 'foo'
      group_foo.save
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('foot')
      expect(group_foo.redirect_routes.temporary.count).to eq(0)
    end
  end

  context 'when a Group with redirected projects is renamed' do
    let!(:group_foo) { create(:group, name: 'foo', path: 'foo') }
    let!(:project) { create(:project, path: 'bar', namespace: group_foo) }

    it 'should create the appropriate redirect routes' do
      expect(project.redirect_routes.temporary.count).to eq(0)
      project.path = 'baz'
      project.save
      expect(project.redirect_routes.temporary.count).to eq(1)
      expect(project.redirect_routes.temporary.first.path).to eq('foo/bar')

      group_foo.path = 'foot'
      group_foo.save
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('foo')
      expect(project.redirect_routes.temporary.count).to eq(2)
      expect(project.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar', 'foo/baz'])

      group_foo.path = 'foo'
      group_foo.save
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('foot')
      expect(group_foo.redirect_routes.temporary.count).to eq(0)
    end
  end

  context 'when a Group with redirected groups is renamed' do
    let!(:group_foo) { create(:group, name: 'foo', path: 'foo') }
    let!(:subgroup_bar) { create(:group, name: 'bar', path: 'bar', parent: group_foo) }

    it 'should create the appropriate redirecct routes' do
      # Renaming subgroup
      subgroup_bar.path = 'baz'
      subgroup_bar.save
      expect(subgroup_bar.redirect_routes.permanent.count).to eq(1)
      expect(subgroup_bar.redirect_routes.permanent.first.path).to eq('foo/bar')

      # Renaming group
      group_foo.path = 'qux'
      group_foo.save
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('foo')
      expect(subgroup_bar.redirect_routes.permanent.count).to eq(2)
      expect(subgroup_bar.redirect_routes.permanent.pluck(:path)).to match_array(['foo/bar', 'foo/baz'])

      # Reclaming foo path
      group_foo.path = 'foo'
      group_foo.save
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('qux')
      expect(subgroup_bar.redirect_routes.permanent.count).to eq(3)
      expect(subgroup_bar.redirect_routes.permanent.pluck(:path)).to match_array(['qux/baz', 'foo/bar', 'foo/baz'])
    end
  end

  context 'when a User with projects is renamed' do
    let!(:user_foo) { create(:user, username: 'foo') }
    let!(:project) { create(:project, path: 'bar', namespace: user_foo.namespace) }

    it 'should create the appropriate redirect routes' do
      user_foo.username = 'foot'
      user_foo.save
      expect(user_foo.namespace.redirect_routes.permanent.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.first.path).to eq('foo')
      expect(project.redirect_routes.temporary.count).to eq(1)
      expect(project.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar'])

      user_foo.username = 'foo'
      user_foo.save
      expect(user_foo.namespace.redirect_routes.permanent.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.first.path).to eq('foot')
      expect(user_foo.namespace.redirect_routes.temporary.count).to eq(0)
    end
  end

  context 'when a User with redirected projects is renamed' do
    let!(:user_foo) { create(:user, username: 'foo') }
    let!(:project) { create(:project, path: 'bar', namespace: user_foo.namespace) }

    it 'should create the appropriate redirect routes' do
      expect(project.redirect_routes.temporary.count).to eq(0)
      project.path = 'baz'
      project.save
      expect(project.redirect_routes.temporary.count).to eq(1)
      expect(project.redirect_routes.temporary.first.path).to eq('foo/bar')

      user_foo.username = 'foot'
      user_foo.save
      expect(user_foo.namespace.redirect_routes.permanent.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.first.path).to eq('foo')
      expect(project.redirect_routes.temporary.count).to eq(2)
      expect(project.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar', 'foo/baz'])

      user_foo.username = 'foo'
      user_foo.save
      expect(user_foo.namespace.redirect_routes.permanent.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.first.path).to eq('foot')
      expect(user_foo.namespace.redirect_routes.temporary.count).to eq(0)
    end
  end

  context 'when a Project is renamed' do
    let(:project) { create(:project, path: 'bar') }

    it 'should create the appropriate redirect routes' do
      project.path = 'baz'
      project.save
      namespace = project.namespace
      expect(project.redirect_routes.permanent.count).to eq(0)
      expect(project.redirect_routes.temporary.count).to eq(1)
      expect(project.redirect_routes.temporary.first.path).to eq("#{namespace.name}/bar")
    end
  end
end
