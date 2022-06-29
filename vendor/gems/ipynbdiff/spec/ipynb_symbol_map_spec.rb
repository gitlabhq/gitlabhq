# frozen_string_literal: true

require 'rspec'
require 'json'
require 'rspec-parameterized'
require 'ipynb_symbol_map'

describe IpynbDiff::IpynbSymbolMap do
  def res(*cases)
    cases&.to_h || []
  end

  describe '#parse_string' do
    using RSpec::Parameterized::TableSyntax

    let(:mapper) { IpynbDiff::IpynbSymbolMap.new(input) }

    where(:input, :result) do
      # Empty string
      '""' | ''
      # Some string with quotes
      '"he\nll\"o"' | 'he\nll\"o'
    end

    with_them do
      it { expect(mapper.parse_string(return_value: true)).to eq(result) }
      it { expect(mapper.parse_string).to be_nil }
      it { expect(mapper.results).to be_empty }
    end

    it 'raises if invalid string' do
      mapper = IpynbDiff::IpynbSymbolMap.new('"')

      expect { mapper.parse_string }.to raise_error(IpynbDiff::InvalidTokenError)
    end

  end

  describe '#parse_object' do
    using RSpec::Parameterized::TableSyntax

    let(:mapper) { IpynbDiff::IpynbSymbolMap.new(notebook, objects_to_ignore) }

    before do
      mapper.parse_object('')
    end

    where(:notebook, :objects_to_ignore, :result) do
      # Empty object
      '{   }' | [] | res
      # Object with string
      '{   "hello"  : "world"   }' | [] | res(['.hello', 0])
      # Object with boolean
      '{   "hello"  : true   }' | [] | res(['.hello', 0])
      # Object with integer
      '{   "hello"  : 1   }' | [] | res(['.hello', 0])
      # Object with 2 properties in the same line
      '{   "hello"  : "world" , "my" : "bad"   }' | [] | res(['.hello', 0], ['.my', 0])
      # Object with 2 properties in the different lines line
      "{   \"hello\"  : \"world\" , \n \n \"my\" : \"bad\"   }" | [] | res(['.hello', 0], ['.my', 2])
      # Object with 2 properties, but one is ignored
      "{   \"hello\"  : \"world\" , \n \n \"my\" : \"bad\"   }" | ['hello'] | res(['.my', 2])
    end

    with_them do
      it { expect(mapper.results).to include(result) }
    end
  end

  describe '#parse_array' do
    using RSpec::Parameterized::TableSyntax

    where(:notebook, :result) do
      # Empty Array
      '[]' | res
      # Array with string value
      '["a"]' | res(['.0', 0])
      # Array with boolean
      '[  true  ]' | res(['.0', 0])
      # Array with integer
      '[  1 ]' | res(['.0', 0])
      # Two values on the same line
      '["a", "b"]' | res(['.0', 0], ['.1', 0])
      # With line breaks'
      "[\n  \"a\"  \n , \n \"b\"  ]" | res(['.0', 1], ['.1', 3])
    end

    let(:mapper) { IpynbDiff::IpynbSymbolMap.new(notebook) }

    before do
      mapper.parse_array('')
    end

    with_them do
      it { expect(mapper.results).to match_array(result) }
    end
  end

  describe '#skip_object' do
    subject { IpynbDiff::IpynbSymbolMap.parse(JSON.pretty_generate(source)) }
  end

  describe '#parse' do

    let(:objects_to_ignore) { [] }

    subject { IpynbDiff::IpynbSymbolMap.parse(JSON.pretty_generate(source), objects_to_ignore) }

    context 'Empty object' do
      let(:source) { {} }

      it { is_expected.to be_empty }
    end

    context 'Object with inner object and number' do
      let(:source) { { obj1: { obj2: 1 } } }

      it { is_expected.to match_array(res(['.obj1', 1], ['.obj1.obj2', 2])) }
    end

    context 'Object with inner object and number, string and array with object' do
      let(:source) { { obj1: { obj2: [123, 2, true], obj3: "hel\nlo", obj4: true, obj5: 123, obj6: 'a' } } }

      it do
        is_expected.to match_array(
          res(['.obj1', 1],
              ['.obj1.obj2', 2],
              ['.obj1.obj2.0', 3],
              ['.obj1.obj2.1', 4],
              ['.obj1.obj2.2', 5],
              ['.obj1.obj3', 7],
              ['.obj1.obj4', 8],
              ['.obj1.obj5', 9],
              ['.obj1.obj6', 10])
        )
      end
    end

    context 'When index is exceeded because of failure' do
      it 'raises an exception' do
        source = '{"\\a": "a\""}'

        mapper = IpynbDiff::IpynbSymbolMap.new(source)

        expect(mapper).to receive(:prev_backslash?).at_least(1).time.and_return(false)

        expect { mapper.parse('') }.to raise_error(IpynbDiff::InvalidTokenError)
      end
    end

    context 'Object with inner object and number, string and array with object' do
      let(:source) { { obj1: { obj2: [123, 2, true], obj3: "hel\nlo", obj4: true, obj5: 123, obj6: { obj7: 'a' } } } }
      let(:objects_to_ignore) { %w(obj2 obj6) }
      it do
        is_expected.to match_array(
                         res(['.obj1', 1],
                             ['.obj1.obj3', 7],
                             ['.obj1.obj4', 8],
                             ['.obj1.obj5', 9],
                       )
                       )
      end
    end
  end
end
