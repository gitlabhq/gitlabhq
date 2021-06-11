# frozen_string_literal: true

require 'spec_helper'
require_migration!('add_default_and_free_plans')

RSpec.describe AddDefaultAndFreePlans do
  describe 'migrate' do
    let(:plans) { table(:plans) }

    context 'when on Gitlab.com' do
      before do
        expect(Gitlab).to receive(:com?) { true }
      end

      it 'creates free and default plans' do
        expect { migrate! }.to change { plans.count }.by 2

        expect(plans.last(2).pluck(:name)).to eq %w[free default]
      end
    end

    context 'when on self-hosted' do
      before do
        expect(Gitlab).to receive(:com?) { false }
      end

      it 'creates only a default plan' do
        expect { migrate! }.to change { plans.count }.by 1

        expect(plans.last.name).to eq 'default'
      end
    end
  end
end
