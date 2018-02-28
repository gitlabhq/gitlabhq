require 'spec_helper'

describe SubmoduleHelper do
  include RepoHelpers

  describe 'submodule links' do
    let(:submodule_item) { double(id: 'hash', path: 'rack') }
    let(:config) { Gitlab.config.gitlab }
    let(:repo) { double() }

    before do
      self.instance_variable_set(:@repository, repo)
    end

    context 'submodule on self' do
      before do
        allow(Gitlab.config.gitlab).to receive(:protocol).and_return('http') # set this just to be sure
      end

      it 'detects ssh on standard port' do
        allow(Gitlab.config.gitlab_shell).to receive(:ssh_port).and_return(22) # set this just to be sure
        allow(Gitlab.config.gitlab_shell).to receive(:ssh_path_prefix).and_return(Settings.send(:build_gitlab_shell_ssh_path_prefix))
        stub_url([config.user, '@', config.host, ':gitlab-org/gitlab-ce.git'].join(''))
        expect(submodule_links(submodule_item)).to eq([namespace_project_path('gitlab-org', 'gitlab-ce'), namespace_project_tree_path('gitlab-org', 'gitlab-ce', 'hash')])
      end

      it 'detects ssh on non-standard port' do
        allow(Gitlab.config.gitlab_shell).to receive(:ssh_port).and_return(2222)
        allow(Gitlab.config.gitlab_shell).to receive(:ssh_path_prefix).and_return(Settings.send(:build_gitlab_shell_ssh_path_prefix))
        stub_url(['ssh://', config.user, '@', config.host, ':2222/gitlab-org/gitlab-ce.git'].join(''))
        expect(submodule_links(submodule_item)).to eq([namespace_project_path('gitlab-org', 'gitlab-ce'), namespace_project_tree_path('gitlab-org', 'gitlab-ce', 'hash')])
      end

      it 'detects http on standard port' do
        allow(Gitlab.config.gitlab).to receive(:port).and_return(80)
        allow(Gitlab.config.gitlab).to receive(:url).and_return(Settings.send(:build_gitlab_url))
        stub_url(['http://', config.host, '/gitlab-org/gitlab-ce.git'].join(''))
        expect(submodule_links(submodule_item)).to eq([namespace_project_path('gitlab-org', 'gitlab-ce'), namespace_project_tree_path('gitlab-org', 'gitlab-ce', 'hash')])
      end

      it 'detects http on non-standard port' do
        allow(Gitlab.config.gitlab).to receive(:port).and_return(3000)
        allow(Gitlab.config.gitlab).to receive(:url).and_return(Settings.send(:build_gitlab_url))
        stub_url(['http://', config.host, ':3000/gitlab-org/gitlab-ce.git'].join(''))
        expect(submodule_links(submodule_item)).to eq([namespace_project_path('gitlab-org', 'gitlab-ce'), namespace_project_tree_path('gitlab-org', 'gitlab-ce', 'hash')])
      end

      it 'works with relative_url_root' do
        allow(Gitlab.config.gitlab).to receive(:port).and_return(80) # set this just to be sure
        allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('/gitlab/root')
        allow(Gitlab.config.gitlab).to receive(:url).and_return(Settings.send(:build_gitlab_url))
        stub_url(['http://', config.host, '/gitlab/root/gitlab-org/gitlab-ce.git'].join(''))
        expect(submodule_links(submodule_item)).to eq([namespace_project_path('gitlab-org', 'gitlab-ce'), namespace_project_tree_path('gitlab-org', 'gitlab-ce', 'hash')])
      end

      it 'works with subgroups' do
        allow(Gitlab.config.gitlab).to receive(:port).and_return(80) # set this just to be sure
        allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('/gitlab/root')
        allow(Gitlab.config.gitlab).to receive(:url).and_return(Settings.send(:build_gitlab_url))
        stub_url(['http://', config.host, '/gitlab/root/gitlab-org/sub/gitlab-ce.git'].join(''))
        expect(submodule_links(submodule_item)).to eq([namespace_project_path('gitlab-org/sub', 'gitlab-ce'), namespace_project_tree_path('gitlab-org/sub', 'gitlab-ce', 'hash')])
      end
    end

    context 'submodule on github.com' do
      it 'detects ssh' do
        stub_url('git@github.com:gitlab-org/gitlab-ce.git')
        expect(submodule_links(submodule_item)).to eq(['https://github.com/gitlab-org/gitlab-ce', 'https://github.com/gitlab-org/gitlab-ce/tree/hash'])
      end

      it 'detects http' do
        stub_url('http://github.com/gitlab-org/gitlab-ce.git')
        expect(submodule_links(submodule_item)).to eq(['https://github.com/gitlab-org/gitlab-ce', 'https://github.com/gitlab-org/gitlab-ce/tree/hash'])
      end

      it 'detects https' do
        stub_url('https://github.com/gitlab-org/gitlab-ce.git')
        expect(submodule_links(submodule_item)).to eq(['https://github.com/gitlab-org/gitlab-ce', 'https://github.com/gitlab-org/gitlab-ce/tree/hash'])
      end

      it 'handles urls with no .git on the end' do
        stub_url('http://github.com/gitlab-org/gitlab-ce')
        expect(submodule_links(submodule_item)).to eq(['https://github.com/gitlab-org/gitlab-ce', 'https://github.com/gitlab-org/gitlab-ce/tree/hash'])
      end

      it 'returns original with non-standard url' do
        stub_url('http://github.com/another/gitlab-org/gitlab-ce.git')
        expect(submodule_links(submodule_item)).to eq([repo.submodule_url_for, nil])
      end
    end

    context 'in-repository submodule' do
      let(:group) { create(:group, name: "Master Project", path: "master-project") }
      let(:project) { create(:project, group: group) }
      before do
        self.instance_variable_set(:@project, project)
      end

      it 'in-repository' do
        stub_url('./')
        expect(submodule_links(submodule_item)).to eq(["/master-project/#{project.path}", "/master-project/#{project.path}/tree/hash"])
      end
    end

    context 'submodule on gitlab.com' do
      it 'detects ssh' do
        stub_url('git@gitlab.com:gitlab-org/gitlab-ce.git')
        expect(submodule_links(submodule_item)).to eq(['https://gitlab.com/gitlab-org/gitlab-ce', 'https://gitlab.com/gitlab-org/gitlab-ce/tree/hash'])
      end

      it 'detects http' do
        stub_url('http://gitlab.com/gitlab-org/gitlab-ce.git')
        expect(submodule_links(submodule_item)).to eq(['https://gitlab.com/gitlab-org/gitlab-ce', 'https://gitlab.com/gitlab-org/gitlab-ce/tree/hash'])
      end

      it 'detects https' do
        stub_url('https://gitlab.com/gitlab-org/gitlab-ce.git')
        expect(submodule_links(submodule_item)).to eq(['https://gitlab.com/gitlab-org/gitlab-ce', 'https://gitlab.com/gitlab-org/gitlab-ce/tree/hash'])
      end

      it 'handles urls with no .git on the end' do
        stub_url('http://gitlab.com/gitlab-org/gitlab-ce')
        expect(submodule_links(submodule_item)).to eq(['https://gitlab.com/gitlab-org/gitlab-ce', 'https://gitlab.com/gitlab-org/gitlab-ce/tree/hash'])
      end

      it 'handles urls with trailing whitespace' do
        stub_url('http://gitlab.com/gitlab-org/gitlab-ce.git  ')
        expect(submodule_links(submodule_item)).to eq(['https://gitlab.com/gitlab-org/gitlab-ce', 'https://gitlab.com/gitlab-org/gitlab-ce/tree/hash'])
      end

      it 'returns original with non-standard url' do
        stub_url('http://gitlab.com/another/gitlab-org/gitlab-ce.git')
        expect(submodule_links(submodule_item)).to eq([repo.submodule_url_for, nil])
      end
    end

    context 'submodule on unsupported' do
      it 'sanitizes unsupported protocols' do
        stub_url('javascript:alert("XSS");')

        expect(helper.submodule_links(submodule_item)).to eq([nil, nil])
      end

      it 'sanitizes unsupported protocols disguised as a repository URL' do
        stub_url('javascript:alert("XSS");foo/bar.git')

        expect(helper.submodule_links(submodule_item)).to eq([nil, nil])
      end

      it 'sanitizes invalid URL with extended ASCII' do
        stub_url('é')

        expect(helper.submodule_links(submodule_item)).to eq([nil, nil])
      end

      it 'returns original' do
        stub_url('http://mygitserver.com/gitlab-org/gitlab-ce')
        expect(submodule_links(submodule_item)).to eq([repo.submodule_url_for, nil])

        stub_url('http://mygitserver.com/gitlab-org/gitlab-ce.git')
        expect(submodule_links(submodule_item)).to eq([repo.submodule_url_for, nil])
      end
    end

    context 'submodules with relative links' do
      let(:group) { create(:group, name: "Master Project", path: "master-project") }
      let(:project) { create(:project, group: group) }
      let(:commit_id) { sample_commit[:id] }

      before do
        self.instance_variable_set(:@project, project)
      end

      it 'one level down' do
        result = relative_self_links('../test.git', commit_id)
        expect(result).to eq(["/#{group.path}/test", "/#{group.path}/test/tree/#{commit_id}"])
      end

      it 'with trailing whitespace' do
        result = relative_self_links('../test.git ', commit_id)
        expect(result).to eq(["/#{group.path}/test", "/#{group.path}/test/tree/#{commit_id}"])
      end

      it 'two levels down' do
        result = relative_self_links('../../test.git', commit_id)
        expect(result).to eq(["/#{group.path}/test", "/#{group.path}/test/tree/#{commit_id}"])
      end

      it 'one level down with namespace and repo' do
        result = relative_self_links('../foobar/test.git', commit_id)
        expect(result).to eq(["/foobar/test", "/foobar/test/tree/#{commit_id}"])
      end

      it 'two levels down with namespace and repo' do
        result = relative_self_links('../foobar/baz/test.git', commit_id)
        expect(result).to eq(["/baz/test", "/baz/test/tree/#{commit_id}"])
      end

      context 'personal project' do
        let(:user) { create(:user) }
        let(:project) { create(:project, namespace: user.namespace) }

        it 'one level down with personal project' do
          result = relative_self_links('../test.git', commit_id)
          expect(result).to eq(["/#{user.username}/test", "/#{user.username}/test/tree/#{commit_id}"])
        end
      end
    end
  end

  def stub_url(url)
    allow(repo).to receive(:submodule_url_for).and_return(url)
  end
end
