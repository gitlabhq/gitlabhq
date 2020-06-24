# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CycleAnalytics::Updater do
  describe 'updates authors' do
    let(:user) { create(:user) }
    let(:events) { [{ 'author_id' => user.id }] }

    it 'maps the correct user' do
      described_class.update!(events, from: 'author_id', to: 'author', klass: User)

      expect(events.first['author']).to eq(user)
    end
  end

  describe 'updates builds' do
    let(:build) { create(:ci_build) }
    let(:events) { [{ 'id' => build.id }] }

    it 'maps the correct build' do
      described_class.update!(events, from: 'id', to: 'build', klass: ::Ci::Build)

      expect(events.first['build']).to eq(build)
    end
  end
end
