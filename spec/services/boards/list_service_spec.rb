require 'spec_helper'

describe Boards::ListService do
  describe '#execute' do
    context 'when board parent is a project' do
      let(:parent) { create(:project) }

      subject(:service) { described_class.new(parent, double) }

      it_behaves_like 'boards list service'
    end

    context 'when board parent is a group' do
      let(:parent) { create(:group) }

      subject(:service) { described_class.new(parent, double) }

      it_behaves_like 'boards list service'
    end
  end
end
