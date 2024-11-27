# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Count::ExactCountStrategy do
  before do
    create_list(:project, 3)
    create(:identity)
  end

  let(:models) { [::Project, ::Identity] }

  subject { described_class.new(models).count }

  describe '#count' do
    it 'counts all models' do
      expect(models).to all(receive(:count).and_call_original)

      expect(subject).to eq({ ::Project => 3, ::Identity => 1 })
    end

    it 'returns default value if count times out' do
      allow(models.first).to receive(:count).and_raise(ActiveRecord::StatementInvalid.new(''))

      expect(subject).to eq({})
    end
  end
end
