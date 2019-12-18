# frozen_string_literal: true

require 'spec_helper'

describe SubmoduleHelper do
  include RepoHelpers

  let(:submodule_item) { double(id: 'hash', path: 'rack') }
  let(:config) { Gitlab.config.gitlab }
  let(:repo) { double }

  shared_examples 'submodule_links' do
    context 'submodule on self' do
      before do
        allow(Gitlab.config.gitlab).to receive(:protocol).and_return('http') # set this just to be sure
      end

      it 'detects ssh on standard port' do
        allow(Gitlab.config.gitlab_shell).to receive(:ssh_port).and_return(22) # set this just to be sure
        allow(Gitlab.config.gitlab_shell).to receive(:ssh_path_prefix).and_return(Settings.send(:build_gitlab_shell_ssh_path_prefix))
        stub_url([config.user, '@', config.host, ':gitlab-org/gitlab-foss.git'].join(''))
        expect(subject).to eq([namespace_project_path('gitlab-org', 'gitlab-foss'), namespace_project_tree_path('gitlab-org', 'gitlab-foss', 'hash')])
      end

      it 'detects ssh on non-standard port' do
        allow(Gitlab.config.gitlab_shell).to receive(:ssh_port).and_return(2222)
        allow(Gitlab.config.gitlab_shell).to receive(:ssh_path_prefix).and_return(Settings.send(:build_gitlab_shell_ssh_path_prefix))
        stub_url(['ssh://', config.user, '@', config.host, ':2222/gitlab-org/gitlab-foss.git'].join(''))
        expect(subject).to eq([namespace_project_path('gitlab-org', 'gitlab-foss'), namespace_project_tree_path('gitlab-org', 'gitlab-foss', 'hash')])
      end

      it 'detects http on standard port' do
        allow(Gitlab.config.gitlab).to receive(:port).and_return(80)
        allow(Gitlab.config.gitlab).to receive(:url).and_return(Settings.send(:build_gitlab_url))
        stub_url(['http://', config.host, '/gitlab-org/gitlab-foss.git'].join(''))
        expect(subject).to eq([namespace_project_path('gitlab-org', 'gitlab-foss'), namespace_project_tree_path('gitlab-org', 'gitlab-foss', 'hash')])
      end

      it 'detects http on non-standard port' do
        allow(Gitlab.config.gitlab).to receive(:port).and_return(3000)
        allow(Gitlab.config.gitlab).to receive(:url).and_return(Settings.send(:build_gitlab_url))
        stub_url(['http://', config.host, ':3000/gitlab-org/gitlab-foss.git'].join(''))
        expect(subject).to eq([namespace_project_path('gitlab-org', 'gitlab-foss'), namespace_project_tree_path('gitlab-org', 'gitlab-foss', 'hash')])
      end

      it 'works with relative_url_root' do
        allow(Gitlab.config.gitlab).to receive(:port).and_return(80) # set this just to be sure
        allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('/gitlab/root')
        allow(Gitlab.config.gitlab).to receive(:url).and_return(Settings.send(:build_gitlab_url))
        stub_url(['http://', config.host, '/gitlab/root/gitlab-org/gitlab-foss.git'].join(''))
        expect(subject).to eq([namespace_project_path('gitlab-org', 'gitlab-foss'), namespace_project_tree_path('gitlab-org', 'gitlab-foss', 'hash')])
      end

      it 'works with subgroups' do
        allow(Gitlab.config.gitlab).to receive(:port).and_return(80) # set this just to be sure
        allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('/gitlab/root')
        allow(Gitlab.config.gitlab).to receive(:url).and_return(Settings.send(:build_gitlab_url))
        stub_url(['http://', config.host, '/gitlab/root/gitlab-org/sub/gitlab-foss.git'].join(''))
        expect(subject).to eq([namespace_project_path('gitlab-org/sub', 'gitlab-foss'), namespace_project_tree_path('gitlab-org/sub', 'gitlab-foss', 'hash')])
      end
    end

    context 'submodule on github.com' do
      it 'detects ssh' do
        stub_url('git@github.com:gitlab-org/gitlab-foss.git')
        expect(subject).to eq(['https://github.com/gitlab-org/gitlab-foss', 'https://github.com/gitlab-org/gitlab-foss/tree/hash'])
      end

      it 'detects http' do
        stub_url('http://github.com/gitlab-org/gitlab-foss.git')
        expect(subject).to eq(['https://github.com/gitlab-org/gitlab-foss', 'https://github.com/gitlab-org/gitlab-foss/tree/hash'])
      end

      it 'detects https' do
        stub_url('https://github.com/gitlab-org/gitlab-foss.git')
        expect(subject).to eq(['https://github.com/gitlab-org/gitlab-foss', 'https://github.com/gitlab-org/gitlab-foss/tree/hash'])
      end

      it 'handles urls with no .git on the end' do
        stub_url('http://github.com/gitlab-org/gitlab-foss')
        expect(subject).to eq(['https://github.com/gitlab-org/gitlab-foss', 'https://github.com/gitlab-org/gitlab-foss/tree/hash'])
      end

      it 'returns original with non-standard url' do
        stub_url('http://github.com/another/gitlab-org/gitlab-foss.git')
        expect(subject).to eq([repo.submodule_url_for, nil])
      end
    end

    context 'in-repository submodule' do
      let(:group) { create(:group, name: "Master Project", path: "master-project") }
      let(:project) { create(:project, group: group) }

      it 'in-repository' do
        allow(repo).to receive(:project).and_return(project)

        stub_url('./')
        expect(subject).to eq(["/master-project/#{project.path}", "/master-project/#{project.path}/tree/hash"])
      end
    end

    context 'submodule on gitlab.com' do
      it 'detects ssh' do
        stub_url('git@gitlab.com:gitlab-org/gitlab-foss.git')
        expect(subject).to eq(['https://gitlab.com/gitlab-org/gitlab-foss', 'https://gitlab.com/gitlab-org/gitlab-foss/tree/hash'])
      end

      it 'detects http' do
        stub_url('http://gitlab.com/gitlab-org/gitlab-foss.git')
        expect(subject).to eq(['https://gitlab.com/gitlab-org/gitlab-foss', 'https://gitlab.com/gitlab-org/gitlab-foss/tree/hash'])
      end

      it 'detects https' do
        stub_url('https://gitlab.com/gitlab-org/gitlab-foss.git')
        expect(subject).to eq(['https://gitlab.com/gitlab-org/gitlab-foss', 'https://gitlab.com/gitlab-org/gitlab-foss/tree/hash'])
      end

      it 'handles urls with no .git on the end' do
        stub_url('http://gitlab.com/gitlab-org/gitlab-foss')
        expect(subject).to eq(['https://gitlab.com/gitlab-org/gitlab-foss', 'https://gitlab.com/gitlab-org/gitlab-foss/tree/hash'])
      end

      it 'handles urls with trailing whitespace' do
        stub_url('http://gitlab.com/gitlab-org/gitlab-foss.git  ')
        expect(subject).to eq(['https://gitlab.com/gitlab-org/gitlab-foss', 'https://gitlab.com/gitlab-org/gitlab-foss/tree/hash'])
      end

      it 'returns original with non-standard url' do
        stub_url('http://gitlab.com/another/gitlab-org/gitlab-foss.git')
        expect(subject).to eq([repo.submodule_url_for, nil])
      end
    end

    context 'submodule on unsupported' do
      it 'sanitizes unsupported protocols' do
        stub_url('javascript:alert("XSS");')

        expect(subject).to eq([nil, nil])
      end

      it 'sanitizes unsupported protocols disguised as a repository URL' do
        stub_url('javascript:alert("XSS");foo/bar.git')

        expect(subject).to eq([nil, nil])
      end

      it 'sanitizes invalid URL with extended ASCII' do
        stub_url('é')

        expect(subject).to eq([nil, nil])
      end

      it 'returns original' do
        stub_url('http://mygitserver.com/gitlab-org/gitlab-foss')

        expect(subject).to eq([repo.submodule_url_for, nil])
      end
    end

    context 'submodules with relative links' do
      let(:group) { create(:group, name: "top group", path: "top-group") }
      let(:project) { create(:project, group: group) }
      let(:repo) { double(:repo, project: project) }

      def expect_relative_link_to_resolve_to(relative_path, expected_path)
        allow(repo).to receive(:submodule_url_for).and_return(relative_path)
        result = subject

        expect(result).to eq([expected_path, "#{expected_path}/tree/#{submodule_item.id}"])
      end

      it 'handles project under same group' do
        expect_relative_link_to_resolve_to('../test.git', "/#{group.path}/test")
      end

      it 'handles trailing whitespace' do
        expect_relative_link_to_resolve_to('../test.git ', "/#{group.path}/test")
      end

      it 'handles project under another top group' do
        expect_relative_link_to_resolve_to('../../baz/test.git ', "/baz/test")
      end

      context 'repo path resolves to be located at root (namespace absent)' do
        it 'returns nil' do
          allow(repo).to receive(:submodule_url_for).and_return('../../test.git')

          result = subject

          expect(result).to eq([nil, nil])
        end
      end

      context 'repo path resolves to be located underneath current project path' do
        it 'returns nil because it is not possible to have repo nested under another repo' do
          allow(repo).to receive(:submodule_url_for).and_return('./test.git')

          result = subject

          expect(result).to eq([nil, nil])
        end
      end

      context 'subgroup' do
        let(:sub_group) { create(:group, parent: group, name: "sub group", path: "sub-group") }
        let(:sub_project) { create(:project, group: sub_group) }

        context 'project in sub group' do
          let(:project) { sub_project }

          it "handles referencing ancestor group's project" do
            expect_relative_link_to_resolve_to('../../../top-group/test.git', "/#{group.path}/test")
          end
        end

        it "handles referencing descendent group's project" do
          expect_relative_link_to_resolve_to('../sub-group/test.git', "/top-group/sub-group/test")
        end

        it "handles referencing another top group's project" do
          expect_relative_link_to_resolve_to('../../frontend/css/test.git', "/frontend/css/test")
        end
      end

      context 'personal project' do
        let(:user) { create(:user) }
        let(:project) { create(:project, namespace: user.namespace) }

        it 'handles referencing another personal project' do
          expect_relative_link_to_resolve_to('../test.git', "/#{user.username}/test")
        end
      end
    end

    context 'unknown submodule' do
      before do
        # When there is no `.gitmodules` file, or if `.gitmodules` does not
        # know the submodule at the specified path,
        # `Repository#submodule_url_for` returns `nil`
        stub_url(nil)
      end

      it 'returns no links' do
        expect(subject).to eq([nil, nil])
      end
    end
  end

  context 'as view helpers in view context' do
    subject { helper.submodule_links(submodule_item) }

    before do
      self.instance_variable_set(:@repository, repo)
    end

    it_behaves_like 'submodule_links'
  end

  context 'as stand-alone module' do
    subject { described_class.submodule_links(submodule_item, nil, repo) }

    it_behaves_like 'submodule_links'
  end

  def stub_url(url)
    allow(repo).to receive(:submodule_url_for).and_return(url)
  end
end
