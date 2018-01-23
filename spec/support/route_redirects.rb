shared_examples 'route redirects for groups, users and projects' do
  before do
    TestEnv.clean_test_path
  end

  describe 'Group scenarios' do
    let!(:group_foo) { create(:group, name: 'foo', path: 'foo') }
    let!(:project_bar) { create(:project, path: 'bar', namespace: group_foo) }

    context 'when a Group with projects is renamed' do
      it 'should create the appropriate redirect routes' do
        group_foo.path = 'foot'
        group_foo.save

        expect(group_foo.redirect_routes.temporary).to be_empty
        expect(group_foo.redirect_routes.permanent.pluck(:path)).to match_array(['foo'])
        expect(project_bar.redirect_routes.temporary).to be_empty
        expect(project_bar.redirect_routes.permanent.pluck(:path)).to match_array(['foo/bar'])
      end
    end

    context 'when a Group with projects reclaims an old path' do
      it 'should create the appropriate redirect routes' do
        group_foo.path = 'foot'
        group_foo.save
        expect(group_foo.redirect_routes.temporary).to be_empty
        expect(group_foo.redirect_routes.permanent.pluck(:path)).to match_array(['foo'])
        expect(project_bar.redirect_routes.temporary).to be_empty
        expect(project_bar.redirect_routes.permanent.pluck(:path)).to match_array(['foo/bar'])

        # Back to foo
        group_foo.path = 'foo'
        group_foo.save
        expect(group_foo.redirect_routes.temporary).to be_empty
        expect(group_foo.redirect_routes.permanent.pluck(:path)).to match_array(['foot'])
        expect(project_bar.redirect_routes.temporary).to be_empty
        expect(project_bar.redirect_routes.permanent.pluck(:path)).to match_array(['foot/bar'])
      end
    end

    context 'when a Group with redirected projects is renamed' do
      it 'should create the appropriate redirect routes' do
        # Renaming project
        project_bar.path = 'baz'
        project_bar.save
        expect(project_bar.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar'])
        expect(project_bar.redirect_routes.permanent).to be_empty

        # Renaming group
        group_foo.path = 'foot'
        group_foo.save
        expect(group_foo.redirect_routes.temporary).to be_empty
        expect(group_foo.redirect_routes.permanent.pluck(:path)).to match_array(['foo'])
        expect(project_bar.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar'])
        expect(project_bar.redirect_routes.permanent.pluck(:path)).to match_array(['foo/baz'])
      end
    end

    context 'when a Group with redirected projects reclaims an old path' do
      it 'should create the appropriate redirect routes' do
        # Renaming project
        project_bar.path = 'baz'
        project_bar.save
        expect(project_bar.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar'])
        expect(project_bar.redirect_routes.permanent).to be_empty

        # Renaming group
        group_foo.path = 'foot'
        group_foo.save
        expect(group_foo.redirect_routes.temporary).to be_empty
        expect(group_foo.redirect_routes.permanent.pluck(:path)).to match_array(['foo'])
        expect(project_bar.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar'])
        expect(project_bar.redirect_routes.permanent.pluck(:path)).to match_array(['foo/baz'])

        # Back to foo
        group_foo.path = 'foo'
        group_foo.save
        expect(group_foo.redirect_routes.temporary).to be_empty
        expect(group_foo.redirect_routes.permanent.pluck(:path)).to match_array(['foot'])
        expect(project_bar.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar'])
        expect(project_bar.redirect_routes.permanent.pluck(:path)).to match_array(['foot/baz'])
      end
    end

    context 'when a Group with redirected groups is renamed', :postgresql do
      let!(:subgroup_foot) { create(:group, name: 'foot', path: 'foot', parent: group_foo) }

      it 'should create the appropriate redirect routes' do
        # Renaming subgroup
        subgroup_foot.path = 'baz'
        subgroup_foot.save
        expect(subgroup_foot.redirect_routes.temporary).to be_empty
        expect(subgroup_foot.redirect_routes.permanent.pluck(:path)).to match_array(['foo/foot'])

        # Renaming group
        group_foo.path = 'qux'
        group_foo.save
        expect(group_foo.redirect_routes.temporary).to be_empty
        expect(group_foo.redirect_routes.permanent.pluck(:path)).to match_array(['foo'])
        expect(subgroup_foot.redirect_routes.temporary).to be_empty
        expect(subgroup_foot.redirect_routes.permanent.pluck(:path)).to match_array(['foo/foot', 'foo/baz'])
      end
    end

    context 'when a Group with redirected groups reclaims an old path', :postgresql do
      let!(:subgroup_foot) { create(:group, name: 'foot', path: 'foot', parent: group_foo) }

      it 'should create the appropriate redirect routes' do
        # Renaming subgroup
        subgroup_foot.path = 'baz'
        subgroup_foot.save
        expect(subgroup_foot.redirect_routes.temporary).to be_empty
        expect(subgroup_foot.redirect_routes.permanent.pluck(:path)).to match_array(['foo/foot'])

        # Renaming group
        group_foo.path = 'qux'
        group_foo.save
        expect(group_foo.redirect_routes.temporary).to be_empty
        expect(group_foo.redirect_routes.permanent.pluck(:path)).to match_array(['foo'])
        expect(subgroup_foot.redirect_routes.temporary).to be_empty
        expect(subgroup_foot.redirect_routes.permanent.pluck(:path)).to match_array(['foo/foot', 'foo/baz'])

        # Back to foo
        group_foo.path = 'foo'
        group_foo.save
        expect(group_foo.redirect_routes.temporary).to be_empty
        expect(group_foo.redirect_routes.permanent.pluck(:path)).to match_array(['qux'])
        expect(subgroup_foot.redirect_routes.temporary).to be_empty
        expect(subgroup_foot.redirect_routes.permanent.pluck(:path)).to match_array(['qux/baz'])
      end
    end
  end

  describe 'User scenarios' do
    let!(:user_foo) { create(:user, username: 'foo') }

    context 'when a User is renamed' do
      it 'should create the appropriate redirect routes' do
        user_foo.username = 'foot'
        user_foo.save

        expect(user_foo.namespace.redirect_routes.temporary).to be_empty
        expect(user_foo.namespace.redirect_routes.permanent.pluck(:path)).to match_array(['foo'])
      end
    end

    context 'when a User with projects is renamed' do
      let!(:project) { create(:project, path: 'bar', namespace: user_foo.namespace) }

      it 'should create the appropriate redirect routes' do
        # Renames user
        user_foo.username = 'foot'
        user_foo.save
        expect(user_foo.namespace.redirect_routes.temporary).to be_empty
        expect(user_foo.namespace.redirect_routes.permanent.pluck(:path)).to match_array(['foo'])
        expect(project.redirect_routes.temporary).to be_empty
        expect(project.redirect_routes.permanent.pluck(:path)).to match_array(['foo/bar'])
      end
    end

    context 'when a User with projects reclaims an old path' do
      let!(:project) { create(:project, path: 'bar', namespace: user_foo.namespace) }

      it 'should create the appropriate redirect routes' do
        # Renames user
        user_foo.username = 'foot'
        user_foo.save
        expect(user_foo.namespace.redirect_routes.temporary).to be_empty
        expect(user_foo.namespace.redirect_routes.permanent.pluck(:path)).to match_array(['foo'])
        expect(project.redirect_routes.temporary).to be_empty
        expect(project.redirect_routes.permanent.pluck(:path)).to match_array(['foo/bar'])

        # Back to foo
        user_foo.username = 'foo'
        user_foo.save
        expect(user_foo.namespace.redirect_routes.temporary).to be_empty
        expect(user_foo.namespace.redirect_routes.permanent.pluck(:path)).to match_array(['foot'])
        expect(project.redirect_routes.temporary).to be_empty
        expect(project.redirect_routes.permanent.pluck(:path)).to match_array(['foot/bar'])
      end
    end

    context 'when a User with redirected projects is renamed' do
      let!(:project) { create(:project, path: 'bar', namespace: user_foo.namespace) }

      it 'should create the appropriate redirect routes' do
        # Renaming project
        project.path = 'baz'
        project.save
        expect(project.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar'])
        expect(project.redirect_routes.permanent).to be_empty

        # Renaming user
        user_foo.username = 'foot'
        user_foo.save
        expect(user_foo.namespace.redirect_routes.temporary).to be_empty
        expect(user_foo.namespace.redirect_routes.permanent.pluck(:path)).to match_array(['foo'])
        expect(project.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar'])
        expect(project.redirect_routes.permanent.pluck(:path)).to match_array(['foo/baz'])
      end
    end

    context 'when a User with redirected projects reclaims an old path' do
      let!(:project) { create(:project, path: 'bar', namespace: user_foo.namespace) }

      it 'should create the appropriate redirect routes' do
        # Renaming project
        project.path = 'baz'
        project.save
        expect(project.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar'])
        expect(project.redirect_routes.permanent).to be_empty

        # Renaming user
        user_foo.username = 'foot'
        user_foo.save
        expect(user_foo.namespace.redirect_routes.temporary).to be_empty
        expect(user_foo.namespace.redirect_routes.permanent.pluck(:path)).to match_array(['foo'])
        expect(project.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar'])
        expect(project.redirect_routes.permanent.pluck(:path)).to match_array(['foo/baz'])

        # Back to foo
        user_foo.username = 'foo'
        user_foo.save
        expect(user_foo.namespace.redirect_routes.temporary).to be_empty
        expect(user_foo.namespace.redirect_routes.permanent.pluck(:path)).to match_array(['foot'])
        expect(project.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar'])
        expect(project.redirect_routes.permanent.pluck(:path)).to match_array(['foot/baz'])
      end
    end
  end

  describe 'Project scenarios' do
    let!(:project_bar) { create(:project, path: 'bar') }

    context 'when a Project is renamed' do
      it 'should create the appropriate redirect routes' do
        # Renaming project
        project_bar.path = 'baz'
        project_bar.save
        expect(project_bar.redirect_routes.temporary.pluck(:path)).to match_array(["#{project_bar.namespace.name}/bar"])
        expect(project_bar.redirect_routes.permanent).to be_empty
      end
    end

    context 'when a Project is renamed multiple times' do
      let(:namespace) { project_bar.namespace }

      it 'should create the appropriate redirect routes' do
        # Renaming project
        project_bar.path = 'baz'
        project_bar.save
        expect(project_bar.redirect_routes.temporary.pluck(:path)).to match_array(["#{namespace.name}/bar"])
        expect(project_bar.redirect_routes.permanent).to be_empty

        project_bar.path = 'bax'
        project_bar.save
        expect(project_bar.redirect_routes.temporary.pluck(:path)).to match_array(["#{namespace.name}/bar", "#{namespace.name}/baz"])
        expect(project_bar.redirect_routes.permanent).to be_empty
      end
    end

    context 'when transferring a nested Project to another Group' do
      let!(:group_foo) { create(:group, name: 'foo', path: 'foo') }
      let!(:project_bar) { create(:project, :repository, path: 'bar', namespace: group_foo) }
      let!(:group_foot) { create(:group, name: 'foot', path: 'foot') }
      let!(:user) { create(:user) }

      it 'should create the appropriate redirect routes' do
        create(:group_member, :owner, group: group_foo, user: user)
        create(:group_member, :owner, group: group_foot, user: user)

        # Transferring project
        Projects::TransferService.new(project_bar, user).execute(group_foot)
        expect(project_bar.namespace).to eq(group_foot)
        expect(project_bar.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar'])
        expect(project_bar.redirect_routes.permanent).to be_empty
        expect(group_foo.redirect_routes).to be_empty
        expect(group_foot.redirect_routes).to be_empty
      end
    end

    context 'when transferring a nested Project to a User' do
      let!(:group_foo) { create(:group, name: 'foo', path: 'foo') }
      let!(:project_bar) { create(:project, :repository, path: 'bar', namespace: group_foo) }
      let!(:user_baz) { create(:user, username: 'baz') }

      it 'should create the appropriate redirect routes' do
        create(:group_member, :owner, group: group_foo, user: user_baz)

        # Transferring project
        Projects::TransferService.new(project_bar, user_baz).execute(user_baz.namespace)
        expect(project_bar.namespace).to eq(user_baz.namespace)
        expect(project_bar.redirect_routes.temporary.pluck(:path)).to match_array(['foo/bar'])
        expect(project_bar.redirect_routes.permanent).to be_empty
        expect(group_foo.redirect_routes).to be_empty
      end
    end
  end
end
