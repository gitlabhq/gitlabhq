require 'uri'

# Class representing one patch operation.
class PatchObj
  attr_accessor :start1, :start2
  attr_accessor :length1, :length2
  attr_accessor :diffs

  ENCODE_REGEX = %r{[^0-9A-Za-z_.;!~*'(),/?:@&=+$\#-]}
  ESCAPED = /%[a-fA-F\d]{2}/

  def self.uri_encode(str, unsafe = ENCODE_REGEX)
    unless unsafe.is_a?(Regexp)
      unsafe = Regexp.new("[#{Regexp.quote(unsafe)}]", false)
    end

    str.gsub(unsafe) do
      us = ::Regexp.last_match(0)
      tmp = ''

      us.each_byte do |uc|
        tmp << format('%%%02X', uc)
      end

      tmp
    end.force_encoding(Encoding::US_ASCII)
  end

  def self.uri_decode(str)
    enc = str.encoding
    enc = Encoding::UTF_8 if enc == Encoding::US_ASCII

    str.gsub(ESCAPED) { [::Regexp.last_match(0)[1, 2]].pack('H2').force_encoding(enc) }
  end

  def initialize
    # Initializes with an empty list of diffs.
    @start1 = nil
    @start2 = nil
    @length1 = 0
    @length2 = 0
    @diffs = []
  end

  # Emulate GNU diff's format
  # Header: @@ -382,8 +481,9 @@
  # Indices are printed as 1-based, not 0-based.
  def to_s
    if length1 == 0
      coords1 = start1.to_s + ",0"
    elsif length1 == 1
      coords1 = (start1 + 1).to_s
    else
      coords1 = (start1 + 1).to_s + "," + length1.to_s
    end

    if length2 == 0
      coords2 = start2.to_s + ",0"
    elsif length2 == 1
      coords2 = (start2 + 1).to_s
    else
      coords2 = (start2 + 1).to_s + "," + length2.to_s
    end
    
    text = '@@ -' + coords1 + ' +' + coords2 + " @@\n"

    # Encode the body of the patch with %xx notation.
    text += diffs.map do |op, data|
      op = case op
            when :insert; '+'
            when :delete; '-'
            when :equal ; ' '
           end
      op + PatchObj.uri_encode(data, /[^0-9A-Za-z_.;!~*'(),\/?:@&=+$\#-]/) + "\n"
    end.join.gsub('%20', ' ')
    
    return text
  end
end
