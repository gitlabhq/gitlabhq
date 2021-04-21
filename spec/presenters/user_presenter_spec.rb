# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserPresenter do
  let_it_be(:user) { create(:user) }

  subject(:presenter) { described_class.new(user) }

  describe '#web_path' do
    it { expect(presenter.web_path).to eq("/#{user.username}") }
  end

  describe '#web_url' do
    it { expect(presenter.web_url).to eq("http://localhost/#{user.username}") }
  end
end
