# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../tooling/docs/event_nodoc'

RSpec.describe Docs::EventNodoc, feature_category: :tooling do
  let(:root) { Dir.mktmpdir }
  let(:nodoc_path) { File.join(root, Docs::EventNodoc::NODOC_FILENAME) }

  before do
    FileUtils.mkdir_p(File.dirname(nodoc_path))
  end

  after do
    FileUtils.remove_entry(root)
  end

  describe '.patterns' do
    context 'when .nodoc file does not exist' do
      it 'returns an empty array' do
        expect(described_class.patterns(root)).to eq([])
      end
    end

    context 'when .nodoc file exists' do
      before do
        File.write(nodoc_path, nodoc_content)
      end

      context 'with entries and comments' do
        let(:nodoc_content) do
          <<~CONTENT
            # This is a comment
            app/events/merge_requests/base_cloud_event.rb
            app/events/work_items/base_event.rb
          CONTENT
        end

        it 'returns non-comment, non-blank lines' do
          expect(described_class.patterns(root)).to eq(
            %w[
              app/events/merge_requests/base_cloud_event.rb
              app/events/work_items/base_event.rb
            ]
          )
        end
      end

      context 'with blank lines' do
        let(:nodoc_content) { "\n\n  \n" }

        it 'returns an empty array' do
          expect(described_class.patterns(root)).to eq([])
        end
      end
    end
  end

  describe '.excluded?' do
    before do
      File.write(nodoc_path, "app/events/merge_requests/base_cloud_event.rb\n")
    end

    it 'returns true when the file path matches a pattern suffix' do
      expect(described_class.excluded?('/full/path/app/events/merge_requests/base_cloud_event.rb', root)).to be true
    end

    it 'returns false when the file path does not match' do
      expect(described_class.excluded?('/full/path/app/events/merge_requests/opened_event.rb', root)).to be false
    end
  end
end
