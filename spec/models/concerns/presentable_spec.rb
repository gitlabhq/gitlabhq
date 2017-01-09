require 'spec_helper'

describe Presentable do
  let(:build) { create(:ci_build) }

  describe '#present' do
    it 'returns a presenter' do
      expect(build.present).to be_a(Ci::Build::Presenter)
    end

    it 'takes optional attributes' do
      expect(build.present(foo: 'bar').foo).to eq('bar')
    end
  end
end
