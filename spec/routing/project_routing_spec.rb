# frozen_string_literal: true

require 'spec_helper'

describe 'project routing' do
  before do
    allow(Project).to receive(:find_by_full_path).and_return(false)
    allow(Project).to receive(:find_by_full_path).with('gitlab/gitlabhq', any_args).and_return(true)
  end

  # Shared examples for a resource inside a Project
  #
  # By default it tests all the default REST actions: index, create, new, edit,
  # show, update, and destroy. You can remove actions by customizing the
  # `actions` variable.
  #
  # It also expects a `controller` variable to be available which defines both
  # the path to the resource as well as the controller name.
  #
  # Examples
  #
  #   # Default behavior
  #   it_behaves_like 'RESTful project resources' do
  #     let(:controller) { 'issues' }
  #   end
  #
  #   # Customizing actions
  #   it_behaves_like 'RESTful project resources' do
  #     let(:actions)    { [:index] }
  #     let(:controller) { 'issues' }
  #   end
  #
  #   # Different controller name and path
  #   it_behaves_like 'RESTful project resources' do
  #     let(:controller) { 'pages_domains' }
  #     let(:controller_path) { 'pages/domains' }
  #   end
  shared_examples 'RESTful project resources' do
    let(:actions) { [:index, :create, :new, :edit, :show, :update, :destroy] }
    let(:controller_path) { controller }

    it 'to #index' do
      expect(get("/gitlab/gitlabhq/#{controller_path}")).to route_to("projects/#{controller}#index", namespace_id: 'gitlab', project_id: 'gitlabhq') if actions.include?(:index)
    end

    it 'to #create' do
      expect(post("/gitlab/gitlabhq/#{controller_path}")).to route_to("projects/#{controller}#create", namespace_id: 'gitlab', project_id: 'gitlabhq') if actions.include?(:create)
    end

    it 'to #new' do
      expect(get("/gitlab/gitlabhq/#{controller_path}/new")).to route_to("projects/#{controller}#new", namespace_id: 'gitlab', project_id: 'gitlabhq') if actions.include?(:new)
    end

    it 'to #edit' do
      expect(get("/gitlab/gitlabhq/#{controller_path}/1/edit")).to route_to("projects/#{controller}#edit", namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1') if actions.include?(:edit)
    end

    it 'to #show' do
      expect(get("/gitlab/gitlabhq/#{controller_path}/1")).to route_to("projects/#{controller}#show", namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1') if actions.include?(:show)
    end

    it 'to #update' do
      expect(put("/gitlab/gitlabhq/#{controller_path}/1")).to route_to("projects/#{controller}#update", namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1') if actions.include?(:update)
    end

    it 'to #destroy' do
      expect(delete("/gitlab/gitlabhq/#{controller_path}/1")).to route_to("projects/#{controller}#destroy", namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1') if actions.include?(:destroy)
    end
  end

  #                 projects POST   /projects(.:format)     projects#create
  #              new_project GET    /projects/new(.:format) projects#new
  #            files_project GET    /:id/files(.:format)    projects#files
  #             edit_project GET    /:id/edit(.:format)     projects#edit
  #                  project GET    /:id(.:format)          projects#show
  #                          PUT    /:id(.:format)          projects#update
  #                          DELETE /:id(.:format)          projects#destroy
  # preview_markdown_project POST   /:id/preview_markdown(.:format) projects#preview_markdown
  describe ProjectsController, 'routing' do
    it 'to #create' do
      expect(post('/projects')).to route_to('projects#create')
    end

    it 'to #new' do
      expect(get('/projects/new')).to route_to('projects#new')
    end

    it 'to #edit' do
      expect(get('/gitlab/gitlabhq/edit')).to route_to('projects#edit', namespace_id: 'gitlab', id: 'gitlabhq')
    end

    describe 'to #show' do
      context 'regular name' do
        it { expect(get('/gitlab/gitlabhq')).to route_to('projects#show', namespace_id: 'gitlab', id: 'gitlabhq') }
      end

      context 'name with dot' do
        before do
          allow(Project).to receive(:find_by_full_path).with('gitlab/gitlabhq.keys', any_args).and_return(true)
        end

        it { expect(get('/gitlab/gitlabhq.keys')).to route_to('projects#show', namespace_id: 'gitlab', id: 'gitlabhq.keys') }
      end

      context 'with nested group' do
        before do
          allow(Project).to receive(:find_by_full_path).with('gitlab/subgroup/gitlabhq', any_args).and_return(true)
        end

        it { expect(get('/gitlab/subgroup/gitlabhq')).to route_to('projects#show', namespace_id: 'gitlab/subgroup', id: 'gitlabhq') }
      end
    end

    it 'to #update' do
      expect(put('/gitlab/gitlabhq')).to route_to('projects#update', namespace_id: 'gitlab', id: 'gitlabhq')
    end

    it 'to #destroy' do
      expect(delete('/gitlab/gitlabhq')).to route_to('projects#destroy', namespace_id: 'gitlab', id: 'gitlabhq')
    end

    it 'to #preview_markdown' do
      expect(post('/gitlab/gitlabhq/preview_markdown')).to(
        route_to('projects#preview_markdown', namespace_id: 'gitlab', id: 'gitlabhq')
      )
    end

    it 'to #resolve' do
      expect(get('/projects/1')).to route_to('projects#resolve', id: '1')
    end
  end

  # members_namespace_project_autocomplete_sources_path        GET /:project_id/autocomplete_sources/members(.:format)        projects/autocomplete_sources#members
  # issues_namespace_project_autocomplete_sources_path         GET /:project_id/autocomplete_sources/issues(.:format)         projects/autocomplete_sources#issues
  # merge_requests_namespace_project_autocomplete_sources_path GET /:project_id/autocomplete_sources/merge_requests(.:format) projects/autocomplete_sources#merge_requests
  # labels_namespace_project_autocomplete_sources_path         GET /:project_id/autocomplete_sources/labels(.:format)         projects/autocomplete_sources#labels
  # milestones_namespace_project_autocomplete_sources_path     GET /:project_id/autocomplete_sources/milestones(.:format)     projects/autocomplete_sources#milestones
  # commands_namespace_project_autocomplete_sources_path       GET /:project_id/autocomplete_sources/commands(.:format)       projects/autocomplete_sources#commands
  # snippets_namespace_project_autocomplete_sources_path       GET /:project_id/autocomplete_sources/snippets(.:format)       projects/autocomplete_sources#snippets
  describe Projects::AutocompleteSourcesController, 'routing' do
    [:members, :issues, :merge_requests, :labels, :milestones, :commands, :snippets].each do |action|
      it "to ##{action}" do
        expect(get("/gitlab/gitlabhq/-/autocomplete_sources/#{action}")).to route_to("projects/autocomplete_sources##{action}", namespace_id: 'gitlab', project_id: 'gitlabhq')
      end
    end

    it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/autocomplete_sources/labels", "/gitlab/gitlabhq/-/autocomplete_sources/labels"
  end

  #  pages_project_wikis GET    /:project_id/wikis/pages(.:format)       projects/wikis#pages
  # history_project_wiki GET    /:project_id/wikis/:id/history(.:format) projects/wikis#history
  #        project_wikis POST   /:project_id/wikis(.:format)             projects/wikis#create
  #    edit_project_wiki GET    /:project_id/wikis/:id/edit(.:format)    projects/wikis#edit
  #         project_wiki GET    /:project_id/wikis/:id(.:format)         projects/wikis#show
  #                      DELETE /:project_id/wikis/:id(.:format)         projects/wikis#destroy
  describe Projects::WikisController, 'routing' do
    it 'to #pages' do
      expect(get('/gitlab/gitlabhq/-/wikis/pages')).to route_to('projects/wikis#pages', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it 'to #history' do
      expect(get('/gitlab/gitlabhq/-/wikis/1/history')).to route_to('projects/wikis#history', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
    end

    it_behaves_like 'RESTful project resources' do
      let(:actions)    { [:create, :edit, :show, :destroy] }
      let(:controller) { 'wikis' }
      let(:controller_path) { '/-/wikis' }
    end

    it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/wikis", "/gitlab/gitlabhq/-/wikis"
    it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/wikis/home/edit", "/gitlab/gitlabhq/-/wikis/home/edit"
  end

  # branches_project_repository GET    /:project_id/repository/branches(.:format) projects/repositories#branches
  #     tags_project_repository GET    /:project_id/repository/tags(.:format)     projects/repositories#tags
  #  archive_project_repository GET    /:project_id/repository/archive(.:format)  projects/repositories#archive
  #     edit_project_repository GET    /:project_id/repository/edit(.:format)     projects/repositories#edit
  describe Projects::RepositoriesController, 'routing' do
    it 'to #archive format:zip' do
      expect(get('/gitlab/gitlabhq/-/archive/master/archive.zip')).to route_to('projects/repositories#archive', namespace_id: 'gitlab', project_id: 'gitlabhq', format: 'zip', id: 'master/archive')
    end

    it 'to #archive format:tar.bz2' do
      expect(get('/gitlab/gitlabhq/-/archive/master/archive.tar.bz2')).to route_to('projects/repositories#archive', namespace_id: 'gitlab', project_id: 'gitlabhq', format: 'tar.bz2', id: 'master/archive')
    end

    it 'to #archive with "/" in route' do
      expect(get('/gitlab/gitlabhq/-/archive/improve/awesome/gitlabhq-improve-awesome.tar.gz')).to route_to('projects/repositories#archive', namespace_id: 'gitlab', project_id: 'gitlabhq', format: 'tar.gz', id: 'improve/awesome/gitlabhq-improve-awesome')
    end

    it 'to #archive_alternative' do
      expect(get('/gitlab/gitlabhq/repository/archive')).to route_to('projects/repositories#archive', namespace_id: 'gitlab', project_id: 'gitlabhq', append_sha: true)
    end

    it 'to #archive_deprecated' do
      expect(get('/gitlab/gitlabhq/repository/master/archive')).to route_to('projects/repositories#archive', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master', append_sha: true)
    end

    it 'to #archive_deprecated format:zip' do
      expect(get('/gitlab/gitlabhq/repository/master/archive.zip')).to route_to('projects/repositories#archive', namespace_id: 'gitlab', project_id: 'gitlabhq', format: 'zip', id: 'master', append_sha: true)
    end

    it 'to #archive_deprecated format:tar.bz2' do
      expect(get('/gitlab/gitlabhq/repository/master/archive.tar.bz2')).to route_to('projects/repositories#archive', namespace_id: 'gitlab', project_id: 'gitlabhq', format: 'tar.bz2', id: 'master', append_sha: true)
    end

    it 'to #archive_deprecated with "/" in route' do
      expect(get('/gitlab/gitlabhq/repository/improve/awesome/archive')).to route_to('projects/repositories#archive', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'improve/awesome', append_sha: true)
    end
  end

  describe Projects::BranchesController, 'routing' do
    it 'to #branches' do
      expect(get('/gitlab/gitlabhq/-/branches')).to route_to('projects/branches#index', namespace_id: 'gitlab', project_id: 'gitlabhq')
      expect(delete('/gitlab/gitlabhq/-/branches/feature%2345')).to route_to('projects/branches#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature#45')
      expect(delete('/gitlab/gitlabhq/-/branches/feature%2B45')).to route_to('projects/branches#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature+45')
      expect(delete('/gitlab/gitlabhq/-/branches/feature@45')).to route_to('projects/branches#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature@45')
      expect(delete('/gitlab/gitlabhq/-/branches/feature%2345/foo/bar/baz')).to route_to('projects/branches#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature#45/foo/bar/baz')
      expect(delete('/gitlab/gitlabhq/-/branches/feature%2B45/foo/bar/baz')).to route_to('projects/branches#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature+45/foo/bar/baz')
      expect(delete('/gitlab/gitlabhq/-/branches/feature@45/foo/bar/baz')).to route_to('projects/branches#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature@45/foo/bar/baz')
    end

    it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/branches", "/gitlab/gitlabhq/-/branches"
  end

  describe Projects::TagsController, 'routing' do
    it 'to #tags' do
      expect(get('/gitlab/gitlabhq/-/tags')).to route_to('projects/tags#index', namespace_id: 'gitlab', project_id: 'gitlabhq')
      expect(delete('/gitlab/gitlabhq/-/tags/feature%2345')).to route_to('projects/tags#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature#45')
      expect(delete('/gitlab/gitlabhq/-/tags/feature%2B45')).to route_to('projects/tags#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature+45')
      expect(delete('/gitlab/gitlabhq/-/tags/feature@45')).to route_to('projects/tags#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature@45')
      expect(delete('/gitlab/gitlabhq/-/tags/feature%2345/foo/bar/baz')).to route_to('projects/tags#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature#45/foo/bar/baz')
      expect(delete('/gitlab/gitlabhq/-/tags/feature%2B45/foo/bar/baz')).to route_to('projects/tags#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature+45/foo/bar/baz')
      expect(delete('/gitlab/gitlabhq/-/tags/feature@45/foo/bar/baz')).to route_to('projects/tags#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature@45/foo/bar/baz')
    end
  end

  #     project_deploy_keys GET    /:project_id/deploy_keys(.:format)          deploy_keys#index
  #                         POST   /:project_id/deploy_keys(.:format)          deploy_keys#create
  #  new_project_deploy_key GET    /:project_id/deploy_keys/new(.:format)      deploy_keys#new
  #      project_deploy_key GET    /:project_id/deploy_keys/:id(.:format)      deploy_keys#show
  # edit_project_deploy_key GET    /:project_id/deploy_keys/:id/edit(.:format) deploy_keys#edit
  #      project_deploy_key PATCH  /:project_id/deploy_keys/:id(.:format)      deploy_keys#update
  #                         DELETE /:project_id/deploy_keys/:id(.:format)      deploy_keys#destroy
  describe Projects::DeployKeysController, 'routing' do
    it_behaves_like 'RESTful project resources' do
      let(:actions)    { [:index, :new, :create, :edit, :update] }
      let(:controller) { 'deploy_keys' }
      let(:controller_path) { '/-/deploy_keys' }
    end

    it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/deploy_keys", "/gitlab/gitlabhq/-/deploy_keys"
  end

  # project_protected_branches GET    /:project_id/protected_branches(.:format)     protected_branches#index
  #                            POST   /:project_id/protected_branches(.:format)     protected_branches#create
  #   project_protected_branch DELETE /:project_id/protected_branches/:id(.:format) protected_branches#destroy
  describe Projects::ProtectedBranchesController, 'routing' do
    it_behaves_like 'RESTful project resources' do
      let(:actions)    { [:index, :create, :destroy] }
      let(:controller) { 'protected_branches' }
      let(:controller_path) { '/-/protected_branches' }
    end
  end

  #    switch_project_refs GET    /:project_id/refs/switch(.:format)              refs#switch
  #  logs_tree_project_ref GET    /:project_id/refs/:id/logs_tree(.:format)       refs#logs_tree
  #  logs_file_project_ref GET    /:project_id/refs/:id/logs_tree/:path(.:format) refs#logs_tree
  describe Projects::RefsController, 'routing' do
    it 'to #switch' do
      expect(get('/gitlab/gitlabhq/refs/switch')).to route_to('projects/refs#switch', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it 'to #logs_tree' do
      expect(get('/gitlab/gitlabhq/refs/stable/logs_tree')).to route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'stable')
      expect(get('/gitlab/gitlabhq/refs/feature%2345/logs_tree')).to route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature#45')
      expect(get('/gitlab/gitlabhq/refs/feature%2B45/logs_tree')).to route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature+45')
      expect(get('/gitlab/gitlabhq/refs/feature@45/logs_tree')).to route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature@45')
      expect(get('/gitlab/gitlabhq/refs/stable/logs_tree/foo/bar/baz')).to route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'stable', path: 'foo/bar/baz')
      expect(get('/gitlab/gitlabhq/refs/feature%2345/logs_tree/foo/bar/baz')).to route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature#45', path: 'foo/bar/baz')
      expect(get('/gitlab/gitlabhq/refs/feature%2B45/logs_tree/foo/bar/baz')).to route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature+45', path: 'foo/bar/baz')
      expect(get('/gitlab/gitlabhq/refs/feature@45/logs_tree/foo/bar/baz')).to route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature@45', path: 'foo/bar/baz')
      expect(get('/gitlab/gitlabhq/refs/stable/logs_tree/files.scss')).to route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'stable', path: 'files.scss')
      assert_routing({ path: "/gitlab/gitlabhq/refs/stable/logs_tree/new%0A%0Aline.txt",
                       method: :get },
                     { controller: 'projects/refs', action: 'logs_tree',
                       namespace_id: 'gitlab', project_id: 'gitlabhq',
                       id: "stable", path: "new\n\nline.txt" })
    end
  end

  describe Projects::MergeRequestsController, 'routing' do
    it 'to #commits' do
      expect(get('/gitlab/gitlabhq/merge_requests/1/commits.json')).to route_to('projects/merge_requests#commits', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', format: 'json')
    end

    it 'to #pipelines' do
      expect(get('/gitlab/gitlabhq/merge_requests/1/pipelines.json')).to route_to('projects/merge_requests#pipelines', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', format: 'json')
    end

    it 'to #merge' do
      expect(post('/gitlab/gitlabhq/merge_requests/1/merge')).to route_to(
        'projects/merge_requests#merge',
        namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1'
      )
    end

    it 'to #show' do
      expect(get('/gitlab/gitlabhq/merge_requests/1.diff')).to route_to('projects/merge_requests#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', format: 'diff')
      expect(get('/gitlab/gitlabhq/merge_requests/1.patch')).to route_to('projects/merge_requests#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', format: 'patch')
      expect(get('/gitlab/gitlabhq/merge_requests/1/diffs')).to route_to('projects/merge_requests#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', tab: 'diffs')
      expect(get('/gitlab/gitlabhq/merge_requests/1/commits')).to route_to('projects/merge_requests#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', tab: 'commits')
      expect(get('/gitlab/gitlabhq/merge_requests/1/pipelines')).to route_to('projects/merge_requests#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', tab: 'pipelines')
    end

    it 'to #show from scoped route' do
      expect(get('/gitlab/gitlabhq/-/merge_requests/1.diff')).to route_to('projects/merge_requests#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', format: 'diff')
      expect(get('/gitlab/gitlabhq/-/merge_requests/1.patch')).to route_to('projects/merge_requests#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', format: 'patch')
      expect(get('/gitlab/gitlabhq/-/merge_requests/1/diffs')).to route_to('projects/merge_requests#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', tab: 'diffs')
    end

    it_behaves_like 'RESTful project resources' do
      let(:controller) { 'merge_requests' }
      let(:actions) { [:index, :edit, :show, :update] }
    end
  end

  describe Projects::MergeRequests::CreationsController, 'routing' do
    it 'to #new' do
      expect(get('/gitlab/gitlabhq/merge_requests/new')).to route_to('projects/merge_requests/creations#new', namespace_id: 'gitlab', project_id: 'gitlabhq')
      expect(get('/gitlab/gitlabhq/merge_requests/new/diffs')).to route_to('projects/merge_requests/creations#new', namespace_id: 'gitlab', project_id: 'gitlabhq', tab: 'diffs')
      expect(get('/gitlab/gitlabhq/merge_requests/new/pipelines')).to route_to('projects/merge_requests/creations#new', namespace_id: 'gitlab', project_id: 'gitlabhq', tab: 'pipelines')
    end

    it 'to #create' do
      expect(post('/gitlab/gitlabhq/merge_requests')).to route_to('projects/merge_requests/creations#create', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it 'to #branch_from' do
      expect(get('/gitlab/gitlabhq/merge_requests/new/branch_from')).to route_to('projects/merge_requests/creations#branch_from', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it 'to #branch_to' do
      expect(get('/gitlab/gitlabhq/merge_requests/new/branch_to')).to route_to('projects/merge_requests/creations#branch_to', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it 'to #pipelines' do
      expect(get('/gitlab/gitlabhq/merge_requests/new/pipelines.json')).to route_to('projects/merge_requests/creations#pipelines', namespace_id: 'gitlab', project_id: 'gitlabhq', format: 'json')
    end

    it 'to #diffs' do
      expect(get('/gitlab/gitlabhq/merge_requests/new/diffs.json')).to route_to('projects/merge_requests/creations#diffs', namespace_id: 'gitlab', project_id: 'gitlabhq', format: 'json')
    end
  end

  describe Projects::MergeRequests::DiffsController, 'routing' do
    it 'to #show' do
      expect(get('/gitlab/gitlabhq/merge_requests/1/diffs.json')).to route_to('projects/merge_requests/diffs#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', format: 'json')
    end
  end

  describe Projects::MergeRequests::ConflictsController, 'routing' do
    it 'to #show' do
      expect(get('/gitlab/gitlabhq/merge_requests/1/conflicts')).to route_to('projects/merge_requests/conflicts#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
    end
  end
  #  raw_project_snippet GET    /:project_id/snippets/:id/raw(.:format)  snippets#raw
  #     project_snippets GET    /:project_id/snippets(.:format)          snippets#index
  #                      POST   /:project_id/snippets(.:format)          snippets#create
  #  new_project_snippet GET    /:project_id/snippets/new(.:format)      snippets#new
  # edit_project_snippet GET    /:project_id/snippets/:id/edit(.:format) snippets#edit
  #      project_snippet GET    /:project_id/snippets/:id(.:format)      snippets#show
  #                      PUT    /:project_id/snippets/:id(.:format)      snippets#update
  #                      DELETE /:project_id/snippets/:id(.:format)      snippets#destroy
  describe SnippetsController, 'routing' do
    it 'to #raw' do
      expect(get('/gitlab/gitlabhq/snippets/1/raw')).to route_to('projects/snippets#raw', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
    end

    it 'to #index' do
      expect(get('/gitlab/gitlabhq/snippets')).to route_to('projects/snippets#index', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it 'to #create' do
      expect(post('/gitlab/gitlabhq/snippets')).to route_to('projects/snippets#create', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it 'to #new' do
      expect(get('/gitlab/gitlabhq/snippets/new')).to route_to('projects/snippets#new', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it 'to #edit' do
      expect(get('/gitlab/gitlabhq/snippets/1/edit')).to route_to('projects/snippets#edit', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
    end

    it 'to #show' do
      expect(get('/gitlab/gitlabhq/snippets/1')).to route_to('projects/snippets#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
    end

    it 'to #update' do
      expect(put('/gitlab/gitlabhq/snippets/1')).to route_to('projects/snippets#update', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
    end

    it 'to #destroy' do
      expect(delete('/gitlab/gitlabhq/snippets/1')).to route_to('projects/snippets#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
    end
  end

  # test_project_hook POST    /:project_id/hooks/:id/test(.:format) hooks#test
  #     project_hooks GET    /:project_id/hooks(.:format)          hooks#index
  #                   POST   /:project_id/hooks(.:format)          hooks#create
  # edit_project_hook GET    /:project_id/hooks/:id/edit(.:format) hooks#edit
  #      project_hook PUT    /:project_id/hooks/:id(.:format)      hooks#update
  #                   DELETE /:project_id/hooks/:id(.:format)      hooks#destroy
  describe Projects::HooksController, 'routing' do
    it 'to #test' do
      expect(post('/gitlab/gitlabhq/hooks/1/test')).to route_to('projects/hooks#test', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
    end

    it_behaves_like 'RESTful project resources' do
      let(:actions)    { [:index, :create, :destroy, :edit, :update] }
      let(:controller) { 'hooks' }
    end
  end

  # retry_namespace_project_hook_hook_log POST /:project_id/hooks/:hook_id/hook_logs/:id/retry(.:format) projects/hook_logs#retry
  # namespace_project_hook_hook_log       GET /:project_id/hooks/:hook_id/hook_logs/:id(.:format)       projects/hook_logs#show
  describe Projects::HookLogsController, 'routing' do
    it 'to #retry' do
      expect(post('/gitlab/gitlabhq/hooks/1/hook_logs/1/retry')).to route_to('projects/hook_logs#retry', namespace_id: 'gitlab', project_id: 'gitlabhq', hook_id: '1', id: '1')
    end

    it 'to #show' do
      expect(get('/gitlab/gitlabhq/hooks/1/hook_logs/1')).to route_to('projects/hook_logs#show', namespace_id: 'gitlab', project_id: 'gitlabhq', hook_id: '1', id: '1')
    end
  end

  # project_commit GET    /:project_id/commit/:id(.:format) commit#show {id: /\h{7,40}/, project_id: /[^\/]+/}
  describe Projects::CommitController, 'routing' do
    it 'to #show' do
      expect(get('/gitlab/gitlabhq/commit/4246fbd')).to route_to('projects/commit#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '4246fbd')
      expect(get('/gitlab/gitlabhq/commit/4246fbd.diff')).to route_to('projects/commit#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '4246fbd', format: 'diff')
      expect(get('/gitlab/gitlabhq/commit/4246fbd.patch')).to route_to('projects/commit#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '4246fbd', format: 'patch')
      expect(get('/gitlab/gitlabhq/commit/4246fbd13872934f72a8fd0d6fb1317b47b59cb5')).to route_to('projects/commit#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '4246fbd13872934f72a8fd0d6fb1317b47b59cb5')
    end
  end

  #    patch_project_commit GET    /:project_id/commits/:id/patch(.:format) commits#patch
  #         project_commits GET    /:project_id/commits(.:format)           commits#index
  #                         POST   /:project_id/commits(.:format)           commits#create
  #          project_commit GET    /:project_id/commits/:id(.:format)       commits#show
  describe Projects::CommitsController, 'routing' do
    it_behaves_like 'RESTful project resources' do
      let(:actions)    { [:show] }
      let(:controller) { 'commits' }
    end

    it 'to #show' do
      expect(get('/gitlab/gitlabhq/commits/master.atom')).to route_to('projects/commits#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master.atom')
    end
  end

  #     project_project_members GET    /:project_id/project_members(.:format)          project_members#index
  #                          POST   /:project_id/project_members(.:format)          project_members#create
  #                          PUT    /:project_id/project_members/:id(.:format)      project_members#update
  #                          DELETE /:project_id/project_members/:id(.:format)      project_members#destroy
  describe Projects::ProjectMembersController, 'routing' do
    it_behaves_like 'RESTful project resources' do
      let(:actions)    { [:index, :create, :update, :destroy] }
      let(:controller) { 'project_members' }
      let(:controller_path) { '/-/project_members' }
    end

    it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/project_members", "/gitlab/gitlabhq/-/project_members"
  end

  #     project_milestones    GET    /:project_id/milestones(.:format)          milestones#index
  #                           POST   /:project_id/milestones(.:format)          milestones#create
  #  new_project_milestone    GET    /:project_id/milestones/new(.:format)      milestones#new
  # edit_project_milestone    GET    /:project_id/milestones/:id/edit(.:format) milestones#edit
  #      project_milestone    GET    /:project_id/milestones/:id(.:format)      milestones#show
  #                           PUT    /:project_id/milestones/:id(.:format)      milestones#update
  #                           DELETE /:project_id/milestones/:id(.:format)      milestones#destroy
  # promote_project_milestone POST /:project_id/milestones/:id/promote          milestones#promote
  describe Projects::MilestonesController, 'routing' do
    it_behaves_like 'RESTful project resources' do
      let(:controller) { 'milestones' }
      let(:actions) { [:index, :create, :new, :edit, :show, :update] }
      let(:controller_path) { '/-/milestones' }
    end

    it 'to #promote' do
      expect(post('/gitlab/gitlabhq/-/milestones/1/promote')).to route_to('projects/milestones#promote', namespace_id: 'gitlab', project_id: 'gitlabhq', id: "1")
    end

    it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/milestones", "/gitlab/gitlabhq/-/milestones"
  end

  # project_labels GET    /:project_id/labels(.:format) labels#index
  describe Projects::LabelsController, 'routing' do
    it 'to #index' do
      expect(get('/gitlab/gitlabhq/-/labels')).to route_to('projects/labels#index', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/labels", "/gitlab/gitlabhq/-/labels"
  end

  #        sort_project_issues POST   /:project_id/issues/sort(.:format)        issues#sort
  # bulk_update_project_issues POST   /:project_id/issues/bulk_update(.:format) issues#bulk_update
  #      search_project_issues GET    /:project_id/issues/search(.:format)      issues#search
  #             project_issues GET    /:project_id/issues(.:format)             issues#index
  #                            POST   /:project_id/issues(.:format)             issues#create
  #          new_project_issue GET    /:project_id/issues/new(.:format)         issues#new
  #         edit_project_issue GET    /:project_id/issues/:id/edit(.:format)    issues#edit
  #              project_issue GET    /:project_id/issues/:id(.:format)         issues#show
  #                            PUT    /:project_id/issues/:id(.:format)         issues#update
  #                            DELETE /:project_id/issues/:id(.:format)         issues#destroy
  describe Projects::IssuesController, 'routing' do
    it 'to #bulk_update' do
      expect(post('/gitlab/gitlabhq/issues/bulk_update')).to route_to('projects/issues#bulk_update', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it_behaves_like 'RESTful project resources' do
      let(:controller) { 'issues' }
      let(:actions) { [:index, :create, :new, :edit, :show, :update] }
    end
  end

  # project_noteable_notes GET    /:project_id/noteable/:target_type/:target_id/notes notes#index
  #                        POST   /:project_id/notes(.:format)                        notes#create
  #           project_note DELETE /:project_id/notes/:id(.:format)                    notes#destroy
  describe Projects::NotesController, 'routing' do
    it 'to #index' do
      expect(get('/gitlab/gitlabhq/noteable/issue/1/notes')).to route_to(
        'projects/notes#index',
        namespace_id: 'gitlab',
        project_id: 'gitlabhq',
        target_type: 'issue',
        target_id: '1'
      )
    end

    it_behaves_like 'RESTful project resources' do
      let(:actions)    { [:create, :destroy] }
      let(:controller) { 'notes' }
    end
  end

  # project_blame GET    /:project_id/blame/:id(.:format) blame#show {id: /[^\0]+/, project_id: /[^\/]+/}
  describe Projects::BlameController, 'routing' do
    it 'to #show' do
      expect(get('/gitlab/gitlabhq/blame/master/app/models/project.rb')).to route_to('projects/blame#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/app/models/project.rb')
      expect(get('/gitlab/gitlabhq/blame/master/files.scss')).to route_to('projects/blame#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/files.scss')
      newline_file = "new\n\nline.txt"
      url_encoded_newline_file = ERB::Util.url_encode(newline_file)
      assert_routing({ path: "/gitlab/gitlabhq/blame/master/#{url_encoded_newline_file}",
                        method: :get },
                    { controller: 'projects/blame', action: 'show',
                      namespace_id: 'gitlab', project_id: 'gitlabhq',
                      id: "master/#{newline_file}" })
    end
  end

  # project_blob GET    /:project_id/blob/:id(.:format) blob#show {id: /[^\0]+/, project_id: /[^\/]+/}
  describe Projects::BlobController, 'routing' do
    it 'to #show' do
      expect(get('/gitlab/gitlabhq/blob/master/app/models/project.rb')).to route_to('projects/blob#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/app/models/project.rb')
      expect(get('/gitlab/gitlabhq/blob/master/app/models/compare.rb')).to route_to('projects/blob#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/app/models/compare.rb')
      expect(get('/gitlab/gitlabhq/blob/master/app/models/diff.js')).to route_to('projects/blob#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/app/models/diff.js')
      expect(get('/gitlab/gitlabhq/blob/master/files.scss')).to route_to('projects/blob#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/files.scss')
      expect(get('/gitlab/gitlabhq/blob/master/blob/index.js')).to route_to('projects/blob#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/blob/index.js')
      expect(get('/gitlab/gitlabhq/blob/blob/master/blob/index.js')).to route_to('projects/blob#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'blob/master/blob/index.js')
      newline_file = "new\n\nline.txt"
      url_encoded_newline_file = ERB::Util.url_encode(newline_file)
      assert_routing({ path: "/gitlab/gitlabhq/blob/blob/master/blob/#{url_encoded_newline_file}",
                        method: :get },
                    { controller: 'projects/blob', action: 'show',
                      namespace_id: 'gitlab', project_id: 'gitlabhq',
                      id: "blob/master/blob/#{newline_file}" })
    end
  end

  # project_tree GET    /:project_id/tree/:id(.:format) tree#show {id: /[^\0]+/, project_id: /[^\/]+/}
  describe Projects::TreeController, 'routing' do
    it 'to #show' do
      expect(get('/gitlab/gitlabhq/tree/master/app/models/project.rb')).to route_to('projects/tree#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/app/models/project.rb')
      expect(get('/gitlab/gitlabhq/tree/master/files.scss')).to route_to('projects/tree#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/files.scss')
      expect(get('/gitlab/gitlabhq/tree/master/tree/files')).to route_to('projects/tree#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/tree/files')
      expect(get('/gitlab/gitlabhq/tree/tree/master/tree/files')).to route_to('projects/tree#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'tree/master/tree/files')
      newline_file = "new\n\nline.txt"
      url_encoded_newline_file = ERB::Util.url_encode(newline_file)
      assert_routing({ path: "/gitlab/gitlabhq/tree/master/#{url_encoded_newline_file}",
                        method: :get },
                    { controller: 'projects/tree', action: 'show',
                      namespace_id: 'gitlab', project_id: 'gitlabhq',
                      id: "master/#{newline_file}" })
    end
  end

  # project_find_file GET /:namespace_id/:project_id/find_file/*id(.:format)  projects/find_file#show {:id=>/[^\0]+/, :namespace_id=>/[a-zA-Z.0-9_\-]+/, :project_id=>/[a-zA-Z.0-9_\-]+(?<!\.atom)/, :format=>/html/}
  # project_files     GET /:namespace_id/:project_id/files/*id(.:format)      projects/find_file#list {:id=>/(?:[^.]|\.(?!json$))+/, :namespace_id=>/[a-zA-Z.0-9_\-]+/, :project_id=>/[a-zA-Z.0-9_\-]+(?<!\.atom)/, :format=>/json/}
  describe Projects::FindFileController, 'routing' do
    it 'to #show' do
      expect(get('/gitlab/gitlabhq/find_file/master')).to route_to('projects/find_file#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master')
      newline_file = "new\n\nline.txt"
      url_encoded_newline_file = ERB::Util.url_encode(newline_file)
      assert_routing({ path: "/gitlab/gitlabhq/find_file/#{url_encoded_newline_file}",
                        method: :get },
                    { controller: 'projects/find_file', action: 'show',
                      namespace_id: 'gitlab', project_id: 'gitlabhq',
                      id: "#{newline_file}" })
    end

    it 'to #list' do
      expect(get('/gitlab/gitlabhq/files/master.json')).to route_to('projects/find_file#list', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master.json')
      newline_file = "new\n\nline.txt"
      url_encoded_newline_file = ERB::Util.url_encode(newline_file)
      assert_routing({ path: "/gitlab/gitlabhq/files/#{url_encoded_newline_file}",
                        method: :get },
                    { controller: 'projects/find_file', action: 'list',
                      namespace_id: 'gitlab', project_id: 'gitlabhq',
                      id: "#{newline_file}" })
    end
  end

  describe Projects::BlobController, 'routing' do
    it 'to #edit' do
      expect(get('/gitlab/gitlabhq/edit/master/app/models/project.rb')).to(
        route_to('projects/blob#edit',
                 namespace_id: 'gitlab', project_id: 'gitlabhq',
                 id: 'master/app/models/project.rb'))
      newline_file = "new\n\nline.txt"
      url_encoded_newline_file = ERB::Util.url_encode(newline_file)
      assert_routing({ path: "/gitlab/gitlabhq/edit/master/docs/#{url_encoded_newline_file}",
                        method: :get },
                      { controller: 'projects/blob', action: 'edit',
                        namespace_id: 'gitlab', project_id: 'gitlabhq',
                        id: "master/docs/#{newline_file}" })
    end

    it 'to #preview' do
      expect(post('/gitlab/gitlabhq/preview/master/app/models/project.rb')).to(
        route_to('projects/blob#preview',
                 namespace_id: 'gitlab', project_id: 'gitlabhq',
                 id: 'master/app/models/project.rb'))
      newline_file = "new\n\nline.txt"
      url_encoded_newline_file = ERB::Util.url_encode(newline_file)
      assert_routing({ path: "/gitlab/gitlabhq/edit/master/docs/#{url_encoded_newline_file}",
                        method: :get },
                      { controller: 'projects/blob', action: 'edit',
                        namespace_id: 'gitlab', project_id: 'gitlabhq',
                        id: "master/docs/#{newline_file}" })
    end
  end

  # project_raw GET    /:project_id/raw/:id(.:format) raw#show {id: /[^\0]+/, project_id: /[^\/]+/}
  describe Projects::RawController, 'routing' do
    it 'to #show' do
      newline_file = "new\n\nline.txt"
      url_encoded_newline_file = ERB::Util.url_encode(newline_file)
      assert_routing({ path: "/gitlab/gitlabhq/raw/master/#{url_encoded_newline_file}",
                        method: :get },
                    { controller: 'projects/raw', action: 'show',
                      namespace_id: 'gitlab', project_id: 'gitlabhq',
                      id: "master/#{newline_file}" })
    end
  end

  # project_compare_index GET    /:project_id/compare(.:format)             compare#index {id: /[^\/]+/, project_id: /[^\/]+/}
  #                       POST   /:project_id/compare(.:format)             compare#create {id: /[^\/]+/, project_id: /[^\/]+/}
  #       project_compare        /:project_id/compare/:from...:to(.:format) compare#show {from: /.+/, to: /.+/, id: /[^\/]+/, project_id: /[^\/]+/}
  describe Projects::CompareController, 'routing' do
    it 'to #index' do
      expect(get('/gitlab/gitlabhq/compare')).to route_to('projects/compare#index', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it 'to #compare' do
      expect(post('/gitlab/gitlabhq/compare')).to route_to('projects/compare#create', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it 'to #show' do
      expect(get('/gitlab/gitlabhq/compare/master...stable')).to     route_to('projects/compare#show', namespace_id: 'gitlab', project_id: 'gitlabhq', from: 'master', to: 'stable')
      expect(get('/gitlab/gitlabhq/compare/issue/1234...stable')).to route_to('projects/compare#show', namespace_id: 'gitlab', project_id: 'gitlabhq', from: 'issue/1234', to: 'stable')
    end
  end

  describe Projects::NetworkController, 'routing' do
    it 'to #show' do
      expect(get('/gitlab/gitlabhq/-/network/master')).to route_to('projects/network#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master')
      expect(get('/gitlab/gitlabhq/-/network/ends-with.json')).to route_to('projects/network#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'ends-with.json')
      expect(get('/gitlab/gitlabhq/-/network/master?format=json')).to route_to('projects/network#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master', format: 'json')
    end

    it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/network/master", "/gitlab/gitlabhq/-/network/master"
  end

  describe Projects::GraphsController, 'routing' do
    it 'to #show' do
      expect(get('/gitlab/gitlabhq/-/graphs/master')).to route_to('projects/graphs#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master')
      expect(get('/gitlab/gitlabhq/-/graphs/ends-with.json')).to route_to('projects/graphs#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'ends-with.json')
      expect(get('/gitlab/gitlabhq/-/graphs/master?format=json')).to route_to('projects/graphs#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master', format: 'json')
    end

    it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/graphs/master", "/gitlab/gitlabhq/-/graphs/master"
  end

  describe Projects::ForksController, 'routing' do
    it 'to #new' do
      expect(get('/gitlab/gitlabhq/-/forks/new')).to route_to('projects/forks#new', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it 'to #create' do
      expect(post('/gitlab/gitlabhq/-/forks')).to route_to('projects/forks#create', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/forks", "/gitlab/gitlabhq/-/forks"
  end

  # project_avatar DELETE /project/avatar(.:format) projects/avatars#destroy
  describe Projects::AvatarsController, 'routing' do
    it 'to #destroy' do
      expect(delete('/gitlab/gitlabhq/-/avatar')).to route_to(
        'projects/avatars#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/avatar", "/gitlab/gitlabhq/-/avatar"
  end

  describe Projects::PagesDomainsController, 'routing' do
    it_behaves_like 'RESTful project resources' do
      let(:actions)    { [:show, :new, :create, :destroy] }
      let(:controller) { 'pages_domains' }
      let(:controller_path) { 'pages/domains' }
    end

    it 'to #destroy with a valid domain name' do
      expect(delete('/gitlab/gitlabhq/pages/domains/my.domain.com')).to route_to('projects/pages_domains#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'my.domain.com')
    end

    it 'to #show with a valid domain' do
      expect(get('/gitlab/gitlabhq/pages/domains/my.domain.com')).to route_to('projects/pages_domains#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'my.domain.com')
    end
  end

  describe Projects::Registry::TagsController, 'routing' do
    describe '#destroy' do
      it 'correctly routes to a destroy action' do
        expect(delete('/gitlab/gitlabhq/registry/repository/1/tags/rc1'))
          .to route_to('projects/registry/tags#destroy',
                       namespace_id: 'gitlab',
                       project_id: 'gitlabhq',
                       repository_id: '1',
                       id: 'rc1')
      end

      it 'takes registry tag name constrains into account' do
        expect(delete('/gitlab/gitlabhq/registry/repository/1/tags/-rc1'))
          .not_to route_to('projects/registry/tags#destroy',
                           namespace_id: 'gitlab',
                           project_id: 'gitlabhq',
                           repository_id: '1',
                           id: '-rc1')
      end
    end
  end

  describe Projects::Settings::RepositoryController, 'routing' do
    it 'to #show' do
      expect(get('/gitlab/gitlabhq/-/settings/repository')).to route_to('projects/settings/repository#show', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/settings/repository", "/gitlab/gitlabhq/-/settings/repository"
  end

  describe Projects::TemplatesController, 'routing' do
    describe '#show' do
      def show_with_template_type(template_type)
        "/gitlab/gitlabhq/templates/#{template_type}/template_name"
      end

      it 'routes when :template_type is `merge_request`' do
        expect(get(show_with_template_type('merge_request'))).to route_to('projects/templates#show', namespace_id: 'gitlab', project_id: 'gitlabhq', template_type: 'merge_request', key: 'template_name', format: 'json')
      end

      it 'routes when :template_type is `issue`' do
        expect(get(show_with_template_type('issue'))).to route_to('projects/templates#show', namespace_id: 'gitlab', project_id: 'gitlabhq', template_type: 'issue', key: 'template_name', format: 'json')
      end

      it 'routes to application#route_not_found when :template_type is unknown' do
        expect(get(show_with_template_type('invalid'))).to route_to('application#route_not_found', unmatched_route: 'gitlab/gitlabhq/templates/invalid/template_name')
      end
    end
  end

  describe Projects::DeployTokensController, 'routing' do
    it 'routes to deploy_tokens#revoke' do
      expect(put("/gitlab/gitlabhq/-/deploy_tokens/1/revoke")).to route_to("projects/deploy_tokens#revoke", namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
    end
  end

  describe Projects::UsagePingController, 'routing' do
    it 'routes to usage_ping#web_ide_clientside_preview' do
      expect(post('/gitlab/gitlabhq/usage_ping/web_ide_clientside_preview')).to route_to('projects/usage_ping#web_ide_clientside_preview', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end
  end

  describe Projects::EnvironmentsController, 'routing' do
    describe 'legacy routing' do
      it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/environments", "/gitlab/gitlabhq/-/environments"
    end
  end

  describe Projects::ClustersController, 'routing' do
    describe 'legacy routing' do
      it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/clusters", "/gitlab/gitlabhq/-/clusters"
    end
  end

  describe Projects::ErrorTrackingController, 'routing' do
    describe 'legacy routing' do
      it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/error_tracking", "/gitlab/gitlabhq/-/error_tracking"
    end
  end

  describe Projects::Serverless, 'routing' do
    describe 'legacy routing' do
      it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/serverless", "/gitlab/gitlabhq/-/serverless"
    end
  end
end
