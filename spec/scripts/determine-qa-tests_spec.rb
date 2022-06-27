# frozen_string_literal: true
require 'fast_spec_helper'

load File.expand_path('../../scripts/determine-qa-tests', __dir__)

RSpec.describe 'scripts/determine-qa-tests' do
  describe DetermineQATests do
    describe '.execute' do
      let(:qa_spec_files) do
        %w[qa/qa/specs/features/browser_ui/1_manage/test1.rb
           qa/qa/specs/features/browser_ui/1_manage/user/test2.rb]
      end

      let(:qa_spec_and_non_spec_files) do
        %w[qa/qa/specs/features/browser_ui/1_manage/test1.rb
           qa/qa/page/admin/menu.rb]
      end

      let(:non_qa_files) do
        %w[rubocop/code_reuse_helpers.rb
           app/components/diffs/overflow_warning_component.rb]
      end

      let(:non_qa_and_feature_flag_files) do
        %w[rubocop/code_reuse_helpers.rb
           app/components/diffs/overflow_warning_component.rb
           config/feature_flags/development/access_token_ajax.yml]
      end

      let(:qa_spec_and_non_qa_files) do
        %w[rubocop/code_reuse_helpers.rb
           app/components/diffs/overflow_warning_component.rb
           qa/qa/specs/features/browser_ui/1_manage/test1.rb]
      end

      let(:qa_non_spec_and_non_qa_files) do
        %w[rubocop/code_reuse_helpers.rb
           app/components/diffs/overflow_warning_component.rb
           qa/qa/page/admin/menu.rb]
      end

      shared_examples 'determine qa tests' do
        context 'when only qa spec files have changed' do
          it 'returns only the changed qa specs' do
            subject = described_class.new({ changed_files: qa_spec_files }.merge(labels))

            expect(subject.execute).to eql qa_spec_files.map { |path| path.delete_prefix("qa/") }.join(' ')
          end
        end

        context 'when qa spec and non spec files have changed' do
          it 'does not return any specs' do
            subject = described_class.new({ changed_files: qa_spec_and_non_spec_files }.merge(labels))
            expect(subject.execute).to be_nil
          end
        end

        context 'when non-qa and feature flag files have changed' do
          it 'does not return any specs' do
            subject = described_class.new({ changed_files: non_qa_and_feature_flag_files }.merge(labels))
            expect(subject.execute).to be_nil
          end
        end

        context 'when qa spec and non-qa files have changed' do
          it 'does not return any specs' do
            subject = described_class.new({ changed_files: qa_spec_and_non_qa_files }.merge(labels))
            expect(subject.execute).to be_nil
          end
        end

        context 'when qa non-spec and non-qa files have changed' do
          it 'does not return any specs' do
            subject = described_class.new({ changed_files: qa_non_spec_and_non_qa_files }.merge(labels))
            expect(subject.execute).to be_nil
          end
        end
      end

      context 'when a devops label is not specified' do
        let(:labels) { { mr_labels: ['type::feature'] } }

        it_behaves_like 'determine qa tests'

        context 'when only non-qa files have changed' do
          it 'does not return any specs' do
            subject = described_class.new({ changed_files: non_qa_files })
            expect(subject.execute).to be_nil
          end
        end
      end

      context 'when a devops label is specified' do
        let(:labels) { { mr_labels: %w[devops::manage type::feature] } }

        it_behaves_like 'determine qa tests'

        context 'when only non-qa files have changed' do
          it 'returns the specs for the devops label' do
            subject = described_class.new({ changed_files: non_qa_files }.merge(labels))
            allow(subject).to receive(:qa_spec_directories_for_devops_stage)
                                .and_return(['qa/qa/specs/features/browser_ui/1_manage/'])
            expect(subject.execute).to eql 'qa/specs/features/browser_ui/1_manage/'
          end
        end
      end
    end
  end
end
