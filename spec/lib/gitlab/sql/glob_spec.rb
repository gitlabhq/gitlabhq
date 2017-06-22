require 'spec_helper'

describe Gitlab::SQL::Glob, lib: true do
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
    query("SELECT #{quote(string)} LIKE #{pattern} AS match")
      .first['match']
  end

  def query(sql)
    result = ActiveRecord::Base.connection.exec_query(sql)

    result.map do |row|
      row.each_with_object({}) do |(column, value), hash|
        hash[column] =
          result.column_types[column].type_cast_from_database(value)
      end
    end
  end

  def quote(string)
    ActiveRecord::Base.connection.quote(string)
  end
end
