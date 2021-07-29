# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::ReadOnly do
  context 'when database is read-only' do
    before do
      allow(Gitlab::Database.main).to receive(:read_only?) { true }
    end

    it_behaves_like 'write access for a read-only GitLab instance'
  end
end
