require 'spec_helper'

describe Gitlab::Utils, lib: true do
<<<<<<< HEAD
  delegate :to_boolean, :which, to: :described_class
=======
  delegate :to_boolean, :boolean_to_yes_no, to: :described_class
>>>>>>> upstream/master

  describe '.to_boolean' do
    it 'accepts booleans' do
      expect(to_boolean(true)).to be(true)
      expect(to_boolean(false)).to be(false)
    end

    it 'converts a valid string to a boolean' do
      expect(to_boolean(true)).to be(true)
      expect(to_boolean('true')).to be(true)
      expect(to_boolean('YeS')).to be(true)
      expect(to_boolean('t')).to be(true)
      expect(to_boolean('1')).to be(true)
      expect(to_boolean('ON')).to be(true)

      expect(to_boolean('FaLse')).to be(false)
      expect(to_boolean('F')).to be(false)
      expect(to_boolean('NO')).to be(false)
      expect(to_boolean('n')).to be(false)
      expect(to_boolean('0')).to be(false)
      expect(to_boolean('oFF')).to be(false)
    end

    it 'converts an invalid string to nil' do
      expect(to_boolean('fals')).to be_nil
      expect(to_boolean('yeah')).to be_nil
      expect(to_boolean('')).to be_nil
      expect(to_boolean(nil)).to be_nil
    end
  end

<<<<<<< HEAD
  describe '.which' do
    it 'finds the full path to an executable binary' do
      expect(File).to receive(:executable?).with('/bin/sh').and_return(true)

      expect(which('sh', 'PATH' => '/bin')).to eq('/bin/sh')
=======
  describe '.boolean_to_yes_no' do
    it 'converts booleans to Yes or No' do
      expect(boolean_to_yes_no(true)).to eq('Yes')
      expect(boolean_to_yes_no(false)).to eq('No')
>>>>>>> upstream/master
    end
  end
end
