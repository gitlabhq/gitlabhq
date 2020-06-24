# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RepositoryUrlBuilder do
  describe '.build' do
    using RSpec::Parameterized::TableSyntax

    where(:factory, :path_generator) do
      :project          | ->(project) { project.full_path }
      :project_snippet  | ->(snippet) { "#{snippet.project.full_path}/snippets/#{snippet.id}" }
      :project_wiki     | ->(wiki)    { "#{wiki.container.full_path}.wiki" }

      :personal_snippet | ->(snippet) { "snippets/#{snippet.id}" }
    end

    with_them do
      let(:container) { build_stubbed(factory) }
      let(:repository) { container.repository }
      let(:path) { path_generator.call(container) }
      let(:url) { subject.build(repository.full_path, protocol: protocol) }

      context 'when passing SSH protocol' do
        let(:protocol) { :ssh }

        it 'returns the SSH URL to the repository' do
          expect(url).to eq("#{Gitlab.config.gitlab_shell.ssh_path_prefix}#{path}.git")
        end
      end

      context 'when passing HTTP protocol' do
        let(:protocol) { :http }

        it 'returns the HTTP URL to the repo without a username' do
          expect(url).to eq("#{Gitlab.config.gitlab.url}/#{path}.git")
          expect(url).not_to include('@')
        end

        it 'includes the custom HTTP clone root if set' do
          clone_root = 'https://git.example.com:51234/mygitlab'
          stub_application_setting(custom_http_clone_url_root: clone_root)

          expect(url).to eq("#{clone_root}/#{path}.git")
        end
      end

      context 'when passing an unsupported protocol' do
        let(:protocol) { :ftp }

        it 'raises an exception' do
          expect { url }.to raise_error(NotImplementedError)
        end
      end
    end
  end
end
