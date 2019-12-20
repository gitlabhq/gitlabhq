# frozen_string_literal: true

shared_examples_for 'only truthy if both enabled and address are truthy' do |target_proc|
  context 'with both enabled and address as truthy values' do
    it 'is truthy' do
      stub_config(enabled: true, address: 'localhost')

      expect(target_proc.call).to be_truthy
    end
  end

  context 'with address only as truthy' do
    it 'is falsey' do
      stub_config(enabled: false, address: 'localhost')

      expect(target_proc.call).to be_falsey
    end
  end

  context 'with enabled only as truthy' do
    it 'is falsey' do
      stub_config(enabled: true, address: nil)

      expect(target_proc.call).to be_falsey
    end
  end

  context 'with neither address nor enabled as truthy' do
    it 'is falsey' do
      stub_config(enabled: false, address: nil)

      expect(target_proc.call).to be_falsey
    end
  end
end
