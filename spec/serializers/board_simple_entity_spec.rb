# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BoardSimpleEntity do
  let_it_be(:project) { create(:project) }
  let_it_be(:board) { create(:board, project: project) }

  subject { described_class.new(board).as_json }

  describe '#name' do
    it 'has `name` attribute' do
      is_expected.to include(:name)
    end
  end
end
