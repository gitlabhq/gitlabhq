# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../scripts/lint-docs-redirects'

RSpec.describe LintDocsRedirect, feature_category: :tooling do
  subject(:linter) { described_class.new }

  let(:navigation_yaml) do
    <<~YAML
      sections:
        - section_title: Releases
          section_url: 'releases/'
          section_categories:
            - category_title: GitLab 19.1 released
              category_url: 'releases/19/gitlab-19-1-released/'
    YAML
  end

  before do
    stub_env('CI', 'true')
    stub_env('CI_PROJECT_PATH', 'gitlab-org/gitlab')

    allow(linter).to receive_messages(
      navigation_file: navigation_yaml,
      merge_request_diff: merge_request_diff
    )
  end

  describe 'converting a page to a Hugo page bundle' do
    context 'when a page is converted to a leaf bundle (index.md) at the same URL' do
      let(:merge_request_diff) do
        [
          {
            'old_path' => 'doc/releases/19/gitlab-19-1-released.md',
            'new_path' => 'doc/releases/19/gitlab-19-1-released.md',
            'deleted_file' => true,
            'diff' => ''
          },
          {
            'old_path' => 'doc/releases/19/gitlab-19-1-released/index.md',
            'new_path' => 'doc/releases/19/gitlab-19-1-released/index.md',
            'new_file' => true,
            'diff' => ''
          },
          {
            'old_path' => 'doc/releases/19/gitlab-19-1-released/clearer-security-labels.md',
            'new_path' => 'doc/releases/19/gitlab-19-1-released/clearer-security-labels.md',
            'new_file' => true,
            'diff' => ''
          }
        ]
      end

      it 'does not error, because the bundle publishes the same URL' do
        expect { linter.execute }.not_to raise_error
      end
    end

    context 'when a page is converted to a branch bundle (_index.md) at the same URL' do
      let(:merge_request_diff) do
        [
          {
            'old_path' => 'doc/releases/19/gitlab-19-1-released.md',
            'new_path' => 'doc/releases/19/gitlab-19-1-released.md',
            'deleted_file' => true,
            'diff' => ''
          },
          {
            'old_path' => 'doc/releases/19/gitlab-19-1-released/_index.md',
            'new_path' => 'doc/releases/19/gitlab-19-1-released/_index.md',
            'new_file' => true,
            'diff' => ''
          }
        ]
      end

      it 'does not error, because the bundle publishes the same URL' do
        expect { linter.execute }.not_to raise_error
      end
    end
  end

  describe 'deleting a page that still has a navigation entry' do
    let(:merge_request_diff) do
      [
        {
          'old_path' => 'doc/releases/19/gitlab-19-1-released.md',
          'new_path' => 'doc/releases/19/gitlab-19-1-released.md',
          'deleted_file' => true,
          'diff' => ''
        }
      ]
    end

    it 'errors, because the URL no longer resolves' do
      expect { linter.execute }.to raise_error(SystemExit)
    end
  end

  describe 'deleting a page that has no navigation entry' do
    let(:merge_request_diff) do
      [
        {
          'old_path' => 'doc/some/orphan-page.md',
          'new_path' => 'doc/some/orphan-page.md',
          'deleted_file' => true,
          'diff' => ''
        }
      ]
    end

    it 'does not error' do
      expect { linter.execute }.not_to raise_error
    end
  end
end
