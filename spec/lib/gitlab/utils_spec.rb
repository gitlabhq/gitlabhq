describe Gitlab::Utils, lib: true do
  def to_boolean(value)
    described_class.to_boolean(value)
  end

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
end
