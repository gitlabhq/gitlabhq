# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WithAssociatedNote, feature_category: :code_review_workflow do
  let(:test_model_class) do
    Class.new(ApplicationRecord) do
      self.table_name = 'suggestions'

      include WithAssociatedNote
    end
  end

  let(:test_instance) { test_model_class.new }

  it { expect(test_instance).to be_a(described_class) }

  describe '#skip_namespace_validation?' do
    it 'returns false by default' do
      expect(test_instance.send(:skip_namespace_validation?)).to be false
    end
  end

  describe '#note_namespace_id' do
    it 'raises NoMethodError when not implemented' do
      expect { test_instance.send(:note_namespace_id) }
        .to raise_error(NoMethodError, 'must implement `note_namespace_id` method')
    end
  end
end
