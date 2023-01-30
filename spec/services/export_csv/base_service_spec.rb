# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExportCsv::BaseService, feature_category: :importers do
  let_it_be(:issue) { create(:issue) }
  let_it_be(:relation) { Issue.all }
  let_it_be(:resource_parent) { issue.project }

  subject { described_class.new(relation, resource_parent) }

  describe '#email' do
    it 'raises NotImplementedError' do
      user = create(:user)

      expect { subject.email(user) }.to raise_error(NotImplementedError)
    end
  end

  describe '#header_to_value_hash' do
    it 'raises NotImplementedError' do
      expect { subject.send(:header_to_value_hash) }.to raise_error(NotImplementedError)
    end
  end

  describe '#associations_to_preload' do
    it 'return []' do
      expect(subject.send(:associations_to_preload)).to eq([])
    end
  end
end
