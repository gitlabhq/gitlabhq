# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::ObservabilityMenu do
  let_it_be(:owner) { create(:user) }
  let_it_be(:root_group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:group) { root_group }
  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  describe '#render?' do
    before do
      allow(menu).to receive(:can?).and_call_original
    end

    context 'when observability is enabled' do
      before do
        allow(Gitlab::Observability).to receive(:observability_enabled?).and_return(true)
      end

      it 'returns true' do
        expect(menu.render?).to eq true
        expect(Gitlab::Observability).to have_received(:observability_enabled?).with(user, group)
      end
    end

    context 'when observability is disabled' do
      before do
        allow(Gitlab::Observability).to receive(:observability_enabled?).and_return(false)
      end

      it 'returns false' do
        expect(menu.render?).to eq false
        expect(Gitlab::Observability).to have_received(:observability_enabled?).with(user, group)
      end
    end
  end
end
