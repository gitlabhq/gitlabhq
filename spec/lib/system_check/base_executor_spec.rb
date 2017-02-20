require 'spec_helper'

describe SystemCheck::BaseExecutor, lib: true do
  class SimpleCheck < SystemCheck::BaseCheck
    def check?
      true
    end
  end

  class OtherCheck < SystemCheck::BaseCheck
    def check?
      false
    end
  end

  subject { described_class.new('Test') }

  describe '#component' do
    it 'returns stored component name' do
      expect(subject.component).to eq('Test')
    end
  end

  describe '#checks' do
    before do
      subject << SimpleCheck
    end

    it 'returns an array of classes' do
      expect(subject.checks).to include(SimpleCheck)
    end
  end

  describe '#<<' do
    before do
      subject << SimpleCheck
    end

    it 'appends a new check to the Set' do
      subject << OtherCheck
      stored_checks = subject.checks.to_a
      expect(stored_checks.first).to eq(SimpleCheck)
      expect(stored_checks.last).to eq(OtherCheck)
    end

    it 'inserts unique itens only' do
      subject << SimpleCheck
      expect(subject.checks.size).to eq(1)
    end
  end
end
