# frozen_string_literal: true

require 'gitlab-dangerfiles'
require 'danger'
require 'danger/plugins/internal/helper'
require 'gitlab/dangerfiles/spec_helper'
require 'rspec-parameterized'

require_relative '../../../tooling/danger/bulk_database_actions'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::BulkDatabaseActions, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }

  let(:mr_url) { 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1' }
  let(:doc_link) { described_class::DOCUMENTATION_LINK }

  let(:comment_text) { "\n#{described_class::COMMENT_TEXT}" }

  let(:file_lines) do
    file_diff.map { |line| line.delete_prefix('+') }
  end

  before do
    allow(bulk_database_actions).to receive(:project_helper).and_return(fake_project_helper)
    allow(bulk_database_actions.project_helper).to receive(:file_lines).and_return(file_lines)
    allow(bulk_database_actions.helper).to receive(:added_files).and_return([filename])
    allow(bulk_database_actions.helper).to receive(:changed_lines).with(filename).and_return(file_diff)
    allow(bulk_database_actions.helper).to receive(:mr_web_url).and_return(mr_url)
  end

  subject(:bulk_database_actions) { fake_danger.new(helper: fake_helper) }

  shared_examples 'no Danger comment' do
    it 'does not comment on the bulk update action usage' do
      expect(bulk_database_actions).not_to receive(:markdown)

      bulk_database_actions.add_comment_for_bulk_database_action_method_usage
    end
  end

  describe '#add_comment_for_bulk_database_action_method_usage' do
    context 'for single line method call' do
      let(:file_diff) do
        [
          "+    def execute",
          "+      pat_family.active.#{method_call}",
          "+",
          "+      ServiceResponse.success",
          "+    end"
        ]
      end

      context 'when file is a non-spec Ruby file' do
        let(:filename) { 'app/services/personal_access_tokens/revoke_token_family_service.rb' }

        using RSpec::Parameterized::TableSyntax

        where(:method_call, :expect_comment?) do
          'update_all(revoked: true)' | true
          'destroy_all'               | true
          'delete_all'                | true
          'update(revoked: true)'     | true
          'delete'                    | true
          'update_two_factor'         | false
          'delete_keys(key)'          | false
          'destroy_hook(hook)'        | false
          'destroy_all_merged'        | false
          'update_all_mirrors'        | false
        end

        with_them do
          it "correctly handles potential bulk database action" do
            if expect_comment?
              expect(bulk_database_actions).to receive(:markdown).with(comment_text, file: filename, line: 2)
            else
              expect(bulk_database_actions).not_to receive(:markdown)
            end

            bulk_database_actions.add_comment_for_bulk_database_action_method_usage
          end
        end
      end

      context 'for spec directories' do
        let(:method_call) { 'update_all(revoked: true)' }

        context 'for FOSS spec file' do
          let(:filename) { 'spec/services/personal_access_tokens/revoke_token_family_service_spec.rb' }

          it_behaves_like 'no Danger comment'
        end

        context 'for EE spec file' do
          let(:filename) { 'ee/spec/services/personal_access_tokens/revoke_token_family_service_spec.rb' }

          it_behaves_like 'no Danger comment'
        end

        context 'for JiHu spec file' do
          let(:filename) { 'jh/spec/services/personal_access_tokens/revoke_token_family_service_spec.rb' }

          it_behaves_like 'no Danger comment'
        end
      end
    end

    context 'for strings' do
      let(:filename) { 'app/services/personal_access_tokens/revoke_token_family_service.rb' }
      let(:file_diff) do
        [
          '+    expect { subject }.to output(',
          '+      "ERROR: Could not update tag"',
          '+    ).to_stderr'
        ]
      end

      it_behaves_like 'no Danger comment'
    end
  end
end
