require 'spec_helper'

describe Gitlab::Import::Github::Mapper::Base, lib: true do
  let(:project) { double }
  let(:client)  { double }

  subject(:mapper) do
    klass = Class.new(described_class)
    klass.new(project, client)
  end

  describe '#each' do
    context 'when klass is not implemented' do
      it 'raises NotImplementedError' do
        expect { mapper.each(&:to_s) }.to raise_error(NotImplementedError)
      end
    end
  end
end
