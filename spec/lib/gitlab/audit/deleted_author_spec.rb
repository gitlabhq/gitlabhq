# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Audit::DeletedAuthor, feature_category: :compliance_management do
  subject(:deleted_author) { described_class.new id: 0, name: 'delete this' }

  describe '#impersonated?' do
    it 'returns false' do
      expect(deleted_author.impersonated?).to be false
    end
  end
end
