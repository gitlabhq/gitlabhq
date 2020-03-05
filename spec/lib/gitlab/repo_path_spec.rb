# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::RepoPath do
  include Gitlab::Routing

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:personal_snippet) { create(:personal_snippet) }
  let_it_be(:project_snippet) { create(:project_snippet, project: project) }
  let_it_be(:redirect) { project.route.create_redirect('foo/bar/baz') }

  describe '.parse' do
    context 'a repository storage path' do
      it 'parses a full repository project path' do
        expect(described_class.parse(project.repository.full_path)).to eq([project, project, Gitlab::GlRepository::PROJECT, nil])
      end

      it 'parses a full wiki project path' do
        expect(described_class.parse(project.wiki.repository.full_path)).to eq([project, project, Gitlab::GlRepository::WIKI, nil])
      end

      it 'parses a personal snippet repository path' do
        expect(described_class.parse("snippets/#{personal_snippet.id}")).to eq([personal_snippet, nil, Gitlab::GlRepository::SNIPPET, nil])
      end

      it 'parses a project snippet repository path' do
        expect(described_class.parse("#{project.full_path}/snippets/#{project_snippet.id}")).to eq([project_snippet, project, Gitlab::GlRepository::SNIPPET, nil])
      end
    end

    context 'a relative path' do
      it 'parses a relative repository path' do
        expect(described_class.parse(project.full_path + '.git')).to eq([project, project, Gitlab::GlRepository::PROJECT, nil])
      end

      it 'parses a relative wiki path' do
        expect(described_class.parse(project.full_path + '.wiki.git')).to eq([project, project, Gitlab::GlRepository::WIKI, nil])
      end

      it 'parses a relative path starting with /' do
        expect(described_class.parse('/' + project.full_path + '.git')).to eq([project, project, Gitlab::GlRepository::PROJECT, nil])
      end

      context 'of a redirected project' do
        let(:redirect) { project.route.create_redirect('foo/bar') }

        it 'parses a relative repository path' do
          expect(described_class.parse(redirect.path + '.git')).to eq([project, project, Gitlab::GlRepository::PROJECT, 'foo/bar'])
        end

        it 'parses a relative wiki path' do
          expect(described_class.parse(redirect.path + '.wiki.git')).to eq([project, project, Gitlab::GlRepository::WIKI, 'foo/bar.wiki'])
        end

        it 'parses a relative path starting with /' do
          expect(described_class.parse('/' + redirect.path + '.git')).to eq([project, project, Gitlab::GlRepository::PROJECT, 'foo/bar'])
        end

        it 'parses a redirected project snippet repository path' do
          expect(described_class.parse(redirect.path + "/snippets/#{project_snippet.id}.git")).to eq([project_snippet, project, Gitlab::GlRepository::SNIPPET, "foo/bar/snippets/#{project_snippet.id}"])
        end
      end
    end

    it 'returns the default type for non existent paths' do
      expect(described_class.parse('path/non-existent.git')).to eq([nil, nil, Gitlab::GlRepository.default_type, nil])
    end
  end

  describe '.find_project' do
    context 'when finding a project by its canonical path' do
      context 'when the cases match' do
        it 'returns the project and false' do
          expect(described_class.find_project(project.full_path)).to eq([project, false])
        end
      end

      context 'when the cases do not match' do
        # This is slightly different than web behavior because on the web it is
        # easy and safe to redirect someone to the correctly-cased URL. For git
        # requests, we should accept wrongly-cased URLs because it is a pain to
        # block people's git operations and force them to update remote URLs.
        it 'returns the project and false' do
          expect(described_class.find_project(project.full_path.upcase)).to eq([project, false])
        end
      end
    end

    context 'when finding a project via a redirect' do
      it 'returns the project and true' do
        expect(described_class.find_project(redirect.path)).to eq([project, true])
      end
    end
  end

  describe '.find_snippet' do
    it 'extracts path and id from personal snippet route' do
      expect(described_class.find_snippet("snippets/#{personal_snippet.id}")).to eq([personal_snippet, false])
    end

    it 'extracts path and id from project snippet route' do
      expect(described_class.find_snippet("#{project.full_path}/snippets/#{project_snippet.id}")).to eq([project_snippet, false])
    end

    it 'returns nil for invalid snippet paths' do
      aggregate_failures do
        expect(described_class.find_snippet("snippets/#{project_snippet.id}")).to eq([nil, false])
        expect(described_class.find_snippet("#{project.full_path}/snippets/#{personal_snippet.id}")).to eq([nil, false])
        expect(described_class.find_snippet('')).to eq([nil, false])
      end
    end

    it 'returns nil for snippets not associated with the project' do
      snippet = create(:project_snippet)

      expect(described_class.find_snippet("#{project.full_path}/snippets/#{snippet.id}")).to eq([nil, false])
    end

    context 'when finding a project snippet via a redirect' do
      it 'returns the project and true' do
        expect(described_class.find_snippet("#{redirect.path}/snippets/#{project_snippet.id}")).to eq([project_snippet, true])
      end
    end
  end
end
