# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::Projects::CreatorService do
  it_behaves_like 'member creation' do
    let_it_be(:source, reload: true) { create(:project, :public) }
    let_it_be(:member_type) { ProjectMember }
  end

  describe '.access_levels' do
    it 'returns Gitlab::Access.sym_options' do
      expect(described_class.access_levels).to eq(Gitlab::Access.sym_options)
    end
  end
end
