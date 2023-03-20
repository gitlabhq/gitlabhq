# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ForksCountService, :use_clean_rails_memory_store_caching, feature_category: :source_code_management do
  let(:project) { build(:project) }

  subject { described_class.new(project) }

  it_behaves_like 'a counter caching service'

  describe '#count' do
    it 'returns the number of forks' do
      allow(subject).to receive(:uncached_count).and_return(1)

      expect(subject.count).to eq(1)
    end
  end
end
