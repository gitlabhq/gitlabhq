shared_examples 'route redirects for groups, users and projects' do
  before do
    TestEnv.clean_test_path
  end

  context 'when a Group with projects is renamed' do
    let!(:group_foo) { create(:group, name: 'foo', path: 'foo') }
    let!(:project_bar) { create(:project, path: 'bar', namespace: group_foo) }

    it 'should create the appropriate redirect routes' do
      group_foo.path = 'foot'
      group_foo.save
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('foo')
      expect(project_bar.redirect_routes.permanent.count).to eq(1)
      expect(project_bar.redirect_routes.permanent.first.path).to eq('foo/bar')
    end
  end

  context 'when a Group with projects reclaims an old path' do
    let!(:group_foo) { create(:group, name: 'foo', path: 'foo') }
    let!(:project_bar) { create(:project, path: 'bar', namespace: group_foo) }

    it 'should create the appropriate redirect routes' do
      group_foo.path = 'foot'
      group_foo.save
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('foo')
      expect(project_bar.redirect_routes.permanent.count).to eq(1)
      expect(project_bar.redirect_routes.permanent.pluck(:path)).to match_array(['foo/bar'])

      # Back to foo
      group_foo.path = 'foo'
      group_foo.save
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('foot')
      expect(project_bar.redirect_routes.permanent.count).to eq(1)
      expect(project_bar.redirect_routes.permanent.pluck(:path)).to match_array(['foot/bar'])
    end
  end

  context 'when a Group with redirected projects is renamed' do
    let!(:group_foo) { create(:group, name: 'foo', path: 'foo') }
    let!(:project_bar) { create(:project, path: 'bar', namespace: group_foo) }

    it 'should create the appropriate redirect routes' do
      expect(project_bar.redirect_routes.count).to eq(0)

      # Renaming project
      project_bar.path = 'baz'
      project_bar.save
      expect(project_bar.redirect_routes.temporary.count).to eq(1)
      expect(project_bar.redirect_routes.temporary.first.path).to eq('foo/bar')

      # Renaming group
      group_foo.path = 'foot'
      group_foo.save
      expect(group_foo.redirect_routes.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('foo')
      expect(project_bar.redirect_routes.count).to eq(2)
      expect(project_bar.redirect_routes.temporary.count).to eq(1)
      expect(project_bar.redirect_routes.temporary.first.path).to eq('foo/bar')
      expect(project_bar.redirect_routes.permanent.count).to eq(1)
      expect(project_bar.redirect_routes.permanent.first.path).to eq('foo/baz')
    end
  end

  context 'when a Group with redirected projects reclaims an old path' do
    let!(:group_foo) { create(:group, name: 'foo', path: 'foo') }
    let!(:project_bar) { create(:project, path: 'bar', namespace: group_foo) }

    it 'should create the appropriate redirect routes' do
      expect(project_bar.redirect_routes.temporary.count).to eq(0)

      # Renaming project
      project_bar.path = 'baz'
      project_bar.save
      expect(project_bar.redirect_routes.temporary.count).to eq(1)
      expect(project_bar.redirect_routes.temporary.first.path).to eq('foo/bar')

      # Renaming group
      group_foo.path = 'foot'
      group_foo.save
      expect(group_foo.redirect_routes.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('foo')
      expect(project_bar.redirect_routes.count).to eq(2)
      expect(project_bar.redirect_routes.temporary.count).to eq(1)
      expect(project_bar.redirect_routes.temporary.first.path).to eq('foo/bar')
      expect(project_bar.redirect_routes.permanent.count).to eq(1)
      expect(project_bar.redirect_routes.permanent.first.path).to eq('foo/baz')

      # Back to foo
      group_foo.path = 'foo'
      group_foo.save
      expect(group_foo.redirect_routes.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('foot')
      expect(project_bar.redirect_routes.count).to eq(1)
      expect(project_bar.redirect_routes.permanent.count).to eq(1)
      expect(project_bar.redirect_routes.permanent.first.path).to eq('foot/baz')
    end
  end

  context 'when a Group with redirected groups is renamed' do
    let!(:group_foo) { create(:group, name: 'foo', path: 'foo') }
    let!(:subgroup_bar) { create(:group, name: 'bar', path: 'bar', parent: group_foo) }

    it 'should create the appropriate redirecct routes' do
      # Renaming subgroup
      subgroup_bar.path = 'baz'
      subgroup_bar.save
      expect(subgroup_bar.redirect_routes.count).to eq(1)
      expect(subgroup_bar.redirect_routes.permanent.count).to eq(1)
      expect(subgroup_bar.redirect_routes.permanent.first.path).to eq('foo/bar')

      # Renaming group
      group_foo.path = 'qux'
      group_foo.save
      expect(group_foo.redirect_routes.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('foo')
      expect(subgroup_bar.redirect_routes.count).to eq(2)
      expect(subgroup_bar.redirect_routes.permanent.count).to eq(2)
      expect(subgroup_bar.redirect_routes.permanent.pluck(:path)).to match_array(['foo/bar', 'foo/baz'])
    end
  end

  context 'when a Group with redirected groups reclaims an old path' do
    let!(:group_foo) { create(:group, name: 'foo', path: 'foo') }
    let!(:subgroup_bar) { create(:group, name: 'bar', path: 'bar', parent: group_foo) }

    it 'should create the appropriate redirect routes' do
      # Renaming subgroup
      subgroup_bar.path = 'baz'
      subgroup_bar.save
      expect(subgroup_bar.redirect_routes.count).to eq(1)
      expect(subgroup_bar.redirect_routes.permanent.count).to eq(1)
      expect(subgroup_bar.redirect_routes.permanent.first.path).to eq('foo/bar')

      # Renaming group
      group_foo.path = 'qux'
      group_foo.save
      expect(group_foo.redirect_routes.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('foo')
      expect(subgroup_bar.redirect_routes.count).to eq(2)
      expect(subgroup_bar.redirect_routes.permanent.count).to eq(2)
      expect(subgroup_bar.redirect_routes.permanent.pluck(:path)).to match_array(['foo/bar', 'foo/baz'])

      # Back to foo
      group_foo.path = 'foo'
      group_foo.save
      expect(group_foo.redirect_routes.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.count).to eq(1)
      expect(group_foo.redirect_routes.permanent.first.path).to eq('qux')
      expect(subgroup_bar.redirect_routes.count).to eq(1)
      expect(subgroup_bar.redirect_routes.permanent.count).to eq(1)
      expect(subgroup_bar.redirect_routes.permanent.pluck(:path)).to match_array(['qux/baz'])
    end
  end

  context 'when a User is renamed' do
    let!(:user_foo) { create(:user, username: 'foo') }

    it 'should create the appropriate redirect routes' do
      user_foo.username = 'foot'
      user_foo.save

      expect(user_foo.namespace.redirect_routes.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.first.path).to eq('foo')
    end
  end

  context 'when a User with projects is renamed' do
    let!(:user_foo) { create(:user, username: 'foo') }
    let!(:project) { create(:project, path: 'bar', namespace: user_foo.namespace) }

    it 'should create the appropriate redirect routes' do
      # Renames user
      user_foo.username = 'foot'
      user_foo.save
      expect(user_foo.namespace.redirect_routes.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.first.path).to eq('foo')
      expect(project.redirect_routes.count).to eq(1)
      expect(project.redirect_routes.permanent.count).to eq(1)
      expect(project.redirect_routes.permanent.first.path).to eq('foo/bar')
    end
  end

  context 'when a User with projects reclaims an old path' do
    let!(:user_foo) { create(:user, username: 'foo') }
    let!(:project) { create(:project, path: 'bar', namespace: user_foo.namespace) }

    it 'should create the appropriate redirect routes' do
      # Renames user
      user_foo.username = 'foot'
      user_foo.save
      expect(user_foo.namespace.redirect_routes.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.first.path).to eq('foo')
      expect(project.redirect_routes.count).to eq(1)
      expect(project.redirect_routes.permanent.count).to eq(1)
      expect(project.redirect_routes.permanent.first.path).to eq('foo/bar')

      # Back to foo
      user_foo.username = 'foo'
      user_foo.save
      expect(user_foo.namespace.redirect_routes.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.first.path).to eq('foot')
      expect(project.redirect_routes.count).to eq(1)
      expect(project.redirect_routes.permanent.count).to eq(1)
      expect(project.redirect_routes.permanent.first.path).to eq('foot/bar')
    end
  end

  context 'when a User with redirected projects is renamed' do
    let!(:user_foo) { create(:user, username: 'foo') }
    let!(:project) { create(:project, path: 'bar', namespace: user_foo.namespace) }

    it 'should create the appropriate redirect routes' do
      expect(project.redirect_routes.temporary.count).to eq(0)

      # Renaming project
      project.path = 'baz'
      project.save
      expect(project.redirect_routes.count).to eq(1)
      expect(project.redirect_routes.temporary.count).to eq(1)
      expect(project.redirect_routes.temporary.first.path).to eq('foo/bar')

      # Renaming user
      user_foo.username = 'foot'
      user_foo.save
      expect(user_foo.namespace.redirect_routes.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.first.path).to eq('foo')
      expect(project.redirect_routes.count).to eq(2)
      expect(project.redirect_routes.temporary.count).to eq(1)
      expect(project.redirect_routes.temporary.first.path).to eq('foo/bar')
      expect(project.redirect_routes.permanent.count).to eq(1)
      expect(project.redirect_routes.permanent.first.path).to eq('foo/baz')
    end
  end

  context 'when a User with redirected projects reclaims an old path' do
    let!(:user_foo) { create(:user, username: 'foo') }
    let!(:project) { create(:project, path: 'bar', namespace: user_foo.namespace) }

    it 'should create the appropriate redirect routes' do
      expect(project.redirect_routes.temporary.count).to eq(0)

      # Renaming project
      project.path = 'baz'
      project.save
      expect(project.redirect_routes.count).to eq(1)
      expect(project.redirect_routes.temporary.count).to eq(1)
      expect(project.redirect_routes.temporary.first.path).to eq('foo/bar')

      # Renaming user
      user_foo.username = 'foot'
      user_foo.save
      expect(user_foo.namespace.redirect_routes.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.first.path).to eq('foo')
      expect(project.redirect_routes.count).to eq(2)
      expect(project.redirect_routes.temporary.count).to eq(1)
      expect(project.redirect_routes.temporary.first.path).to eq('foo/bar')
      expect(project.redirect_routes.permanent.count).to eq(1)
      expect(project.redirect_routes.permanent.first.path).to eq('foo/baz')

      # Back to foo
      user_foo.username = 'foo'
      user_foo.save
      expect(user_foo.namespace.redirect_routes.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.count).to eq(1)
      expect(user_foo.namespace.redirect_routes.permanent.first.path).to eq('foot')
      expect(project.redirect_routes.count).to eq(1)
      expect(project.redirect_routes.permanent.count).to eq(1)
      expect(project.redirect_routes.permanent.first.path).to eq('foot/baz')
    end
  end

  context 'when a Project is renamed' do
    let(:project_bar) { create(:project, path: 'bar') }

    it 'should create the appropriate redirect routes' do
      expect(project_bar.redirect_routes.count).to eq(0)

      # Renaming project
      project_bar.path = 'baz'
      project_bar.save
      expect(project_bar.redirect_routes.count).to eq(1)
      expect(project_bar.redirect_routes.temporary.count).to eq(1)
      expect(project_bar.redirect_routes.temporary.first.path).to eq("#{project_bar.namespace.name}/bar")
    end
  end

  context 'when a Project is renamed multiple times' do
    let(:project_bar) { create(:project, path: 'bar') }
    let(:namespace) { project_bar.namespace }

    it 'should create the appropriate redirect routes' do
      expect(project_bar.redirect_routes.count).to eq(0)

      # Renaming project
      project_bar.path = 'baz'
      project_bar.save
      expect(project_bar.redirect_routes.count).to eq(1)
      expect(project_bar.redirect_routes.temporary.count).to eq(1)
      expect(project_bar.redirect_routes.temporary.first.path).to eq("#{namespace.name}/bar")

      project_bar.path = 'bax'
      project_bar.save
      expect(project_bar.redirect_routes.count).to eq(2)
      expect(project_bar.redirect_routes.temporary.count).to eq(2)
      expect(project_bar.redirect_routes.temporary.pluck(:path)).to match_array(["#{namespace.name}/bar", "#{namespace.name}/baz"])
    end
  end

  context 'when transferring a nested Project to another group' do
    let!(:group_foo) { create(:group, name: 'foo', path: 'foo') }
    let!(:project_bar) { create(:project, :repository, path: 'bar', namespace: group_foo) }
    let!(:group_foot) { create(:group, name: 'foot', path: 'foot') }
    let!(:user) { create(:user) }

    it 'should create the appropriate redirect routes' do
      create(:group_member, :owner, group: group_foo, user: user)
      create(:group_member, :owner, group: group_foot, user: user)
      expect(project_bar.redirect_routes.count).to eq(0)

      # Transferring project
      Projects::TransferService.new(project_bar, user).execute(group_foot)
      expect(project_bar.namespace).to eq(group_foot)
      expect(project_bar.redirect_routes.count).to eq(1)
      expect(project_bar.redirect_routes.temporary.count).to eq(1)
      expect(project_bar.redirect_routes.temporary.first.path).to eq('foo/bar')
      expect(group_foo.redirect_routes.count).to eq(0)
      expect(group_foot.redirect_routes.count).to eq(0)
    end
  end
end
