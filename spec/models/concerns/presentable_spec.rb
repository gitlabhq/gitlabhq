# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Presentable do
  let(:build) { Ci::Build.new }

  describe '#present' do
    it 'returns a presenter' do
      expect(build.present).to be_a(Ci::BuildPresenter)
    end

    it 'takes optional attributes' do
      expect(build.present(foo: 'bar').foo).to eq('bar')
    end
  end
end
