require 'spec_helper'

describe Gitlab::SQL::Glob do
  describe '.to_like' do
    it 'matches * as %' do
      expect(glob('apple', '*')).to be(true)
      expect(glob('apple', 'app*')).to be(true)
      expect(glob('apple', 'apple*')).to be(true)
      expect(glob('apple', '*pple')).to be(true)
      expect(glob('apple', 'ap*le')).to be(true)

      expect(glob('apple', '*a')).to be(false)
      expect(glob('apple', 'app*a')).to be(false)
      expect(glob('apple', 'ap*l')).to be(false)
    end

    it 'matches % literally' do
      expect(glob('100%', '100%')).to be(true)

      expect(glob('100%', '%')).to be(false)
    end

    it 'matches _ literally' do
      expect(glob('^_^', '^_^')).to be(true)

      expect(glob('^A^', '^_^')).to be(false)
    end
  end

  def glob(string, pattern)
    match(string, subject.to_like(quote(pattern)))
  end

  def match(string, pattern)
    value = query("SELECT #{quote(string)} LIKE #{pattern}")
              .rows.flatten.first

    case value
    when 't', 1
      true
    else
      false
    end
  end

  def query(sql)
    ActiveRecord::Base.connection.select_all(sql)
  end

  def quote(string)
    ActiveRecord::Base.connection.quote(string)
  end
end
