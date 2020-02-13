# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GitAccessSnippet do
  include GitHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:personal_snippet) { create(:personal_snippet, :private, :repository) }

  let(:protocol) { 'ssh' }
  let(:changes) { Gitlab::GitAccess::ANY }
  let(:push_access_check) { access.check('git-receive-pack', changes) }
  let(:pull_access_check) { access.check('git-upload-pack', changes) }
  let(:snippet) { personal_snippet }
  let(:actor) { personal_snippet.author }

  describe 'when feature flag :version_snippets is enabled' do
    it 'allows push and pull access' do
      aggregate_failures do
        expect { pull_access_check }.not_to raise_error
        expect { push_access_check }.not_to raise_error
      end
    end
  end

  describe 'when feature flag :version_snippets is disabled' do
    before do
      stub_feature_flags(version_snippets: false)
    end

    it 'does not allow push and pull access' do
      aggregate_failures do
        expect { push_access_check }.to raise_snippet_not_found
        expect { pull_access_check }.to raise_snippet_not_found
      end
    end
  end

  describe '#check_snippet_accessibility!' do
    context 'when the snippet exists' do
      it 'allows push and pull access' do
        aggregate_failures do
          expect { pull_access_check }.not_to raise_error
          expect { push_access_check }.not_to raise_error
        end
      end
    end

    context 'when the snippet is nil' do
      let(:snippet) { nil }

      it 'blocks push and pull with "not found"' do
        aggregate_failures do
          expect { pull_access_check }.to raise_snippet_not_found
          expect { push_access_check }.to raise_snippet_not_found
        end
      end
    end

    context 'when the snippet does not have a repository' do
      let(:snippet) { build_stubbed(:personal_snippet) }

      it 'blocks push and pull with "not found"' do
        aggregate_failures do
          expect { pull_access_check }.to raise_snippet_not_found
          expect { push_access_check }.to raise_snippet_not_found
        end
      end
    end
  end

  private

  def access
    described_class.new(actor, snippet, protocol,
                        authentication_abilities: [],
                        namespace_path: nil, project_path: nil,
                        redirected_path: nil, auth_result_type: nil)
  end

  def raise_snippet_not_found
    raise_error(Gitlab::GitAccess::NotFoundError, Gitlab::GitAccess::ERROR_MESSAGES[:snippet_not_found])
  end
end
