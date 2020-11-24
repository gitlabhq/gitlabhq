# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WhatsNew::ItemPresenter do
  let(:present) { Gitlab::WhatsNew::ItemPresenter.present(item) }
  let(:item) { { "packages" => %w(Premium Ultimate) } }
  let(:gitlab_com) { true }

  before do
    allow(Gitlab).to receive(:com?).and_return(gitlab_com)
  end

  describe '.present' do
    context 'when on Gitlab.com' do
      it 'transforms package names to gitlab.com friendly package names' do
        expect(present).to eq({ "packages" => %w(Silver Gold) })
      end
    end

    context 'when not on Gitlab.com' do
      let(:gitlab_com) { false }

      it 'does not transform package names' do
        expect(present).to eq({ "packages" => %w(Premium Ultimate) })
      end
    end
  end
end
