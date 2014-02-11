require 'spec_helper'

describe SubmoduleHelper do
  describe 'submodule links' do
    let(:submodule_item) { double(id: 'hash', path: 'rack') }
    let(:config) { Gitlab.config.gitlab }
    let(:repo) { double() }

    before do
      self.instance_variable_set(:@repository, repo)
    end

    context 'submodule on self' do
      before do
        Gitlab.config.gitlab.stub(protocol: 'http') # set this just to be sure
      end

      it 'should detect ssh on standard port' do
        Gitlab.config.gitlab.stub(ssh_port: 22) # set this just to be sure
        stub_url([ config.user, '@', config.host, ':gitlab-org/gitlab-ce.git' ].join(''))
        submodule_links(submodule_item).should == [ project_path('gitlab-org/gitlab-ce'), project_tree_path('gitlab-org/gitlab-ce', 'hash') ]
      end

      it 'should detect ssh on non-standard port' do
        Gitlab.config.gitlab_shell.stub(ssh_port: 2222)
        Gitlab.config.gitlab_shell.stub(ssh_path_prefix: Settings.send(:build_gitlab_shell_ssh_path_prefix))
        stub_url([ 'ssh://', config.user, '@', config.host, ':2222/gitlab-org/gitlab-ce.git' ].join(''))
        submodule_links(submodule_item).should == [ project_path('gitlab-org/gitlab-ce'), project_tree_path('gitlab-org/gitlab-ce', 'hash') ]
      end

      it 'should detect http on standard port' do
        Gitlab.config.gitlab.stub(port: 80)
        Gitlab.config.gitlab.stub(url: Settings.send(:build_gitlab_url))
        stub_url([ 'http://', config.host, '/gitlab-org/gitlab-ce.git' ].join(''))
        submodule_links(submodule_item).should == [ project_path('gitlab-org/gitlab-ce'), project_tree_path('gitlab-org/gitlab-ce', 'hash') ]
      end

      it 'should detect http on non-standard port' do
        Gitlab.config.gitlab.stub(port: 3000)
        Gitlab.config.gitlab.stub(url: Settings.send(:build_gitlab_url))
        stub_url([ 'http://', config.host, ':3000/gitlab-org/gitlab-ce.git' ].join(''))
        submodule_links(submodule_item).should == [ project_path('gitlab-org/gitlab-ce'), project_tree_path('gitlab-org/gitlab-ce', 'hash') ]
      end

      it 'should work with relative_url_root' do
        Gitlab.config.gitlab.stub(port: 80) # set this just to be sure
        Gitlab.config.gitlab.stub(relative_url_root: '/gitlab/root')
        Gitlab.config.gitlab.stub(url: Settings.send(:build_gitlab_url))
        stub_url([ 'http://', config.host, '/gitlab/root/gitlab-org/gitlab-ce.git' ].join(''))
        submodule_links(submodule_item).should == [ project_path('gitlab-org/gitlab-ce'), project_tree_path('gitlab-org/gitlab-ce', 'hash') ]
      end
    end

    context 'submodule on github.com' do
      it 'should detect ssh' do
        stub_url('git@github.com:gitlab-org/gitlab-ce.git')
        submodule_links(submodule_item).should == [ 'https://github.com/gitlab-org/gitlab-ce', 'https://github.com/gitlab-org/gitlab-ce/tree/hash' ]
      end

      it 'should detect http' do
        stub_url('http://github.com/gitlab-org/gitlab-ce.git')
        submodule_links(submodule_item).should == [ 'https://github.com/gitlab-org/gitlab-ce', 'https://github.com/gitlab-org/gitlab-ce/tree/hash' ]
      end

      it 'should detect https' do
        stub_url('https://github.com/gitlab-org/gitlab-ce.git')
        submodule_links(submodule_item).should == [ 'https://github.com/gitlab-org/gitlab-ce', 'https://github.com/gitlab-org/gitlab-ce/tree/hash' ]
      end

      it 'should return original with non-standard url' do
        stub_url('http://github.com/gitlab-org/gitlab-ce')
        submodule_links(submodule_item).should == [ repo.submodule_url_for, nil ]

        stub_url('http://github.com/another/gitlab-org/gitlab-ce.git')
        submodule_links(submodule_item).should == [ repo.submodule_url_for, nil ]
      end
    end

    context 'submodule on gitlab.com' do
      it 'should detect ssh' do
        stub_url('git@gitlab.com:gitlab-org/gitlab-ce.git')
        submodule_links(submodule_item).should == [ 'https://gitlab.com/gitlab-org/gitlab-ce', 'https://gitlab.com/gitlab-org/gitlab-ce/tree/hash' ]
      end

      it 'should detect http' do
        stub_url('http://gitlab.com/gitlab-org/gitlab-ce.git')
        submodule_links(submodule_item).should == [ 'https://gitlab.com/gitlab-org/gitlab-ce', 'https://gitlab.com/gitlab-org/gitlab-ce/tree/hash' ]
      end

      it 'should detect https' do
        stub_url('https://gitlab.com/gitlab-org/gitlab-ce.git')
        submodule_links(submodule_item).should == [ 'https://gitlab.com/gitlab-org/gitlab-ce', 'https://gitlab.com/gitlab-org/gitlab-ce/tree/hash' ]
      end

      it 'should return original with non-standard url' do
        stub_url('http://gitlab.com/gitlab-org/gitlab-ce')
        submodule_links(submodule_item).should == [ repo.submodule_url_for, nil ]

        stub_url('http://gitlab.com/another/gitlab-org/gitlab-ce.git')
        submodule_links(submodule_item).should == [ repo.submodule_url_for, nil ]
      end
    end

    context 'submodule on unsupported' do
      it 'should return original' do
        stub_url('http://mygitserver.com/gitlab-org/gitlab-ce')
        submodule_links(submodule_item).should == [ repo.submodule_url_for, nil ]

        stub_url('http://mygitserver.com/gitlab-org/gitlab-ce.git')
        submodule_links(submodule_item).should == [ repo.submodule_url_for, nil ]
      end
    end
  end

  def stub_url(url)
    repo.stub(submodule_url_for: url)
  end
end
