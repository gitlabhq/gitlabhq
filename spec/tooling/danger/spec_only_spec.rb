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

  describe '#add_or_remove_label' do
    context 'when all changed files are *_spec.rb files' do
      before do
        allow(fake_helper).to receive(:all_changed_files)
          .and_return(%w[spec/models/user_spec.rb spec/services/foo_spec.rb])
      end

      it 'adds the label if not already present' do
        allow(fake_helper).to receive(:mr_labels).and_return([])

        spec_only.add_or_remove_label

        expect(fake_helper.labels_to_add).to include('pipeline:spec-only')
      end

      it 'does nothing if label already present' do
        allow(fake_helper).to receive(:mr_labels).and_return(['pipeline:spec-only'])

        spec_only.add_or_remove_label

        expect(fake_helper.labels_to_add).to be_empty
      end
    end

    context 'when changed files include non-spec files' do
      before do
        allow(fake_helper).to receive(:all_changed_files).and_return(%w[spec/models/user_spec.rb app/models/user.rb])
      end

      it 'removes the label if present' do
        allow(fake_helper).to receive(:mr_labels).and_return(['pipeline:spec-only'])

        expect(fake_api).to receive(:update_merge_request).with(1, 2, remove_labels: 'pipeline:spec-only')

        spec_only.add_or_remove_label
      end

      it 'does nothing if label not present' do
        allow(fake_helper).to receive(:mr_labels).and_return([])

        expect(fake_api).not_to receive(:update_merge_request)

        spec_only.add_or_remove_label
      end
    end

    context 'when there are no changed files' do
      before do
        allow(fake_helper).to receive_messages(all_changed_files: [], mr_labels: [])
      end

      it 'does not add the label' do
        spec_only.add_or_remove_label

        expect(fake_helper.labels_to_add).to be_empty
      end
    end
  end
end
