# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'git_http routing' do
  describe 'code repositories' do
    it_behaves_like 'git repository routes' do
      let(:path) { '/gitlab-org/gitlab-test.git' }
    end

    it_behaves_like 'git repository routes with fallback for git-upload-pack' do
      let(:path) { '/gitlab-org/gitlab-test.git' }
    end
  end

  describe 'wiki repositories' do
    context 'in project' do
      let(:path) { '/gitlab-org/gitlab-test.wiki.git' }

      it_behaves_like 'git repository routes'
      it_behaves_like 'git repository routes with fallback for git-upload-pack'

      describe 'redirects', type: :request do
        let(:web_path) { '/gitlab-org/gitlab-test/-/wikis' }

        it 'redirects namespace/project.wiki.git to the project wiki' do
          expect(get(path)).to redirect_to(web_path)
        end

        it 'preserves query parameters' do
          expect(get("#{path}?foo=bar&baz=qux")).to redirect_to("#{web_path}?foo=bar&baz=qux")
        end

        it 'only redirects when the format is .git' do
          expect(get(path.delete_suffix('.git'))).not_to redirect_to(web_path)
          expect(get(path.delete_suffix('.git') + '.json')).not_to redirect_to(web_path)
        end
      end
    end

    context 'in toplevel group' do
      it_behaves_like 'git repository routes' do
        let(:path) { '/gitlab-org.wiki.git' }
      end

      it_behaves_like 'git repository routes with fallback for git-upload-pack' do
        let(:path) { '/gitlab-org.wiki.git' }
      end
    end

    context 'in child group' do
      it_behaves_like 'git repository routes' do
        let(:path) { '/gitlab-org/child.wiki.git' }
      end

      it_behaves_like 'git repository routes with fallback for git-upload-pack' do
        let(:path) { '/gitlab-org/child.wiki.git' }
      end
    end
  end

  describe 'snippet repositories' do
    context 'personal snippet' do
      it_behaves_like 'git repository routes' do
        let(:path) { '/snippets/123.git' }
      end

      it_behaves_like 'git repository routes without fallback' do
        let(:path) { '/snippets/123.git' }
      end
    end

    context 'project snippet' do
      it_behaves_like 'git repository routes' do
        let(:path) { '/gitlab-org/gitlab-test/snippets/123.git' }
      end

      it_behaves_like 'git repository routes with fallback' do
        let(:path) { '/gitlab-org/gitlab-test/snippets/123.git' }
      end
    end
  end
end
