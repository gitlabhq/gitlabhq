# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/spec_only'

RSpec.describe Tooling::Danger::SpecOnly, feature_category: :tooling do
  include_context 'with dangerfile'

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_api) { double('GitLab API') } # rubocop:disable RSpec/VerifiedDoubles -- type is not relevant

  subject(:spec_only) { fake_danger.new(helper: fake_helper) }

  before do
    allow(spec_only).to receive_message_chain(:gitlab, :api).and_return(fake_api)
    allow(spec_only).to receive_message_chain(:gitlab, :mr_json).and_return({ 'project_id' => 1, 'iid' => 2 })
    allow(fake_helper).to receive(:labels_to_add).and_return([])
  end

  shared_examples 'eligible for spec-only' do
    context 'when label is not present' do
      before do
        allow(fake_helper).to receive(:mr_labels).and_return([])
      end

      it 'adds the label' do
        spec_only.add_or_remove_label

        expect(fake_helper.labels_to_add).to include('pipeline:spec-only')
      end
    end

    context 'when label is already present' do
      before do
        allow(fake_helper).to receive(:mr_labels).and_return(['pipeline:spec-only'])
      end

      it 'does nothing' do
        spec_only.add_or_remove_label

        expect(fake_helper.labels_to_add).to be_empty
      end
    end
  end

  shared_examples 'not eligible for spec-only' do
    context 'when label is present' do
      before do
        allow(fake_helper).to receive(:mr_labels).and_return(['pipeline:spec-only'])
      end

      it 'removes the label' do
        expect(fake_api).to receive(:update_merge_request).with(1, 2, remove_labels: 'pipeline:spec-only')

        spec_only.add_or_remove_label
      end
    end

    context 'when label is not present' do
      before do
        allow(fake_helper).to receive(:mr_labels).and_return([])
      end

      it 'does nothing' do
        expect(fake_api).not_to receive(:update_merge_request)

        spec_only.add_or_remove_label

        expect(fake_helper.labels_to_add).not_to include('pipeline:spec-only')
      end
    end
  end

  describe '#add_or_remove_label' do
    context 'when all changed files are spec files' do
      before do
        allow(fake_helper).to receive(:all_changed_files)
          .and_return(%w[spec/models/user_spec.rb spec/frontend/foo_spec.js])
      end

      it_behaves_like 'eligible for spec-only'
    end

    context 'when changed files are spec files in ee/' do
      before do
        allow(fake_helper).to receive(:all_changed_files)
          .and_return(%w[ee/spec/models/license_spec.rb ee/spec/services/foo_spec.rb])
      end

      it_behaves_like 'eligible for spec-only'
    end

    context 'when changed files include spec files and doc files' do
      before do
        allow(fake_helper).to receive(:all_changed_files)
          .and_return(%w[spec/models/user_spec.rb doc/api/users.md .rubocop/feature.yml])
      end

      it_behaves_like 'eligible for spec-only'
    end

    context 'when changed files include spec files and non-doc code files' do
      before do
        allow(fake_helper).to receive(:all_changed_files)
          .and_return(%w[spec/models/user_spec.rb app/models/user.rb])
      end

      it_behaves_like 'not eligible for spec-only'
    end

    context 'when changed files include only doc files without spec files' do
      before do
        allow(fake_helper).to receive(:all_changed_files)
          .and_return(%w[doc/api/users.md doc/development/testing.md])
      end

      it_behaves_like 'not eligible for spec-only'
    end

    context 'when changed files include only non-spec code files' do
      before do
        allow(fake_helper).to receive(:all_changed_files)
          .and_return(%w[app/models/user.rb lib/gitlab/utils.rb])
      end

      it_behaves_like 'not eligible for spec-only'
    end

    context 'when there are no changed files' do
      before do
        allow(fake_helper).to receive(:all_changed_files).and_return([])
      end

      it_behaves_like 'not eligible for spec-only'
    end
  end
end
