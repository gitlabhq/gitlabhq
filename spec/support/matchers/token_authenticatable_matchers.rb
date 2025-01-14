# frozen_string_literal: true

module TokenAuthenticatableMatchers
  extend RSpec::Matchers::DSL

  ROUTING_PAYLOAD_REGEX =
    %r{
      (c:\w+\n)?
      (g:\w+\n)?
      o:\w+
      (\np:\w+)?
      (\nu:\w+)?
    }mx

  ROUTABLE_TOKEN_REGEX =
    %r{
      \A
      ([\w\-]+){0,20}? # prefix
      [\w+\-]{27,300} # base64 payload
      \.
      [0-9a-z]{2} # base64 payload length holder
      [0-9a-z]{7} # crc
      \z
    }mx
  BASE64_PAYLOAD_LENGTH_HOLDER_BYTES =
    Authn::TokenField::Generator::RoutableToken::BASE64_PAYLOAD_LENGTH_HOLDER_BYTES
  CRC_BYTES = Authn::TokenField::Generator::RoutableToken::CRC_BYTES

  def generate_routable_token(routing_payload, random_bytes:, prefix: '')
    base64_payload = Base64.urlsafe_encode64(
      "#{routing_payload}#{random_bytes}#{[random_bytes.size].pack('C')}", padding: false
    )
    base64_payload_length = base64_payload.size.to_s(36)
      .rjust(BASE64_PAYLOAD_LENGTH_HOLDER_BYTES, '0')
    checksummable_payload = "#{prefix}#{base64_payload}.#{base64_payload_length}"
    crc = Zlib.crc32(checksummable_payload).to_s(36).rjust(CRC_BYTES, '0')

    "#{checksummable_payload}#{crc}"
  end

  def decoded_payload(token)
    base64_payload_length = base64_payload_length(token)
    offset = BASE64_PAYLOAD_LENGTH_HOLDER_BYTES + CRC_BYTES + 1

    Base64.urlsafe_decode64(token[-offset - base64_payload_length, base64_payload_length])
  end

  def base64_payload_length(token)
    offset = BASE64_PAYLOAD_LENGTH_HOLDER_BYTES + CRC_BYTES

    token[-offset, BASE64_PAYLOAD_LENGTH_HOLDER_BYTES].to_i(36)
  end

  def decoded_random_bytes(token)
    payload = decoded_payload(token)
    random_bytes_length = random_bytes_length(payload)
    offset = random_bytes_length + 1

    payload[-offset, random_bytes_length]
  end

  def random_bytes_length(payload)
    payload[-1].unpack1("C")
  end

  def decoded_routing_payload(token)
    payload = decoded_payload(token)

    payload[0, routing_payload_length(payload)]
  end

  def routing_payload_length(payload)
    payload.size - random_bytes_length(payload) - 1
  end

  def token_crc(token)
    token[-CRC_BYTES, CRC_BYTES].to_i(36)
  end

  def full_token(payload, prefix: '')
    "#{prefix}#{payload}"
  end

  def digested_token(token)
    Gitlab::CryptoHelper.sha256(token)
  end

  matcher :be_a_token do
    match do |actual_token|
      @expected_token =
        if @routing_payload
          generate_routable_token(@routing_payload, random_bytes: @random_bytes.to_s, prefix: @prefix.to_s)
        else
          full_token(@payload, prefix: @prefix.to_s)
        end

      actual_token == expected_token
    end

    chain :with_payload do |payload|
      @payload = payload
    end

    chain :with_routing_payload do |routing_payload|
      @routing_payload = routing_payload
    end

    chain :and_random_bytes do |random_bytes|
      @random_bytes = random_bytes
    end

    chain :and_prefix do |prefix|
      @prefix = prefix
    end

    failure_message do |actual_token|
      expectation_msg = "Expected token:\n#{@expected_token}\n"
      expectation_msg << if @routing_payload
                           "Expected routing payload\n#{@routing_payload}\n" \
                             "got\n#{decoded_routing_payload(actual_token)}"
                         else
                           "Expected payload\n#{@routing_payload}\n" \
                             "got\n#{actual_token.delete_prefix(@prefix.to_s)}"
                         end
    end
  end

  matcher :be_a_digested_token do
    match do |actual_token_digest|
      @expected_token =
        if @routing_payload
          generate_routable_token(@routing_payload, random_bytes: @random_bytes.to_s, prefix: @prefix.to_s)
        else
          full_token(@payload, prefix: @prefix.to_s)
        end

      actual_token_digest == digested_token(@expected_token)
    end

    chain :with_payload do |payload|
      @payload = payload
    end

    chain :with_routing_payload do |routing_payload|
      @routing_payload = routing_payload
    end

    chain :and_random_bytes do |random_bytes|
      @random_bytes = random_bytes
    end

    chain :and_prefix do |prefix|
      @prefix = prefix
    end

    failure_message do |actual_token_digest|
      "Expected token digest:\n#{digested_token(@expected_token)}\ngot\n#{actual_token_digest}."
    end
  end

  matcher :be_a_routable_token do
    match do |actual_token|
      result = actual_token.match?(ROUTABLE_TOKEN_REGEX)
      result &&=
        if @payload
          decoded_routing_payload(actual_token) == @payload
        else
          decoded_routing_payload(actual_token).match?(ROUTING_PAYLOAD_REGEX)
        end

      @expected_crc = Zlib.crc32(actual_token[...-CRC_BYTES])

      result && token_crc(actual_token) == @expected_crc
    end

    chain :with_payload do |payload|
      @payload = payload
    end

    chain :with_prefix do |prefix|
      @prefix = prefix
    end

    chain :and_prefix do |prefix|
      @prefix = prefix
    end

    failure_message do |actual_token|
      expectation_msg =
        "Expected\n#{actual_token}\nto match\n#{ROUTABLE_TOKEN_REGEX}\n" \
          "and #{token_crc(actual_token)} to equal #{@expected_crc}\n"
      expectation_msg << if @payload # rubocop:disable Cop/LineBreakAroundConditionalBlock: -- doesn't make sense here
                           "and\n#{decoded_routing_payload(actual_token)}\nto equal\n#{@payload}"
                         else
                           expectation_msg << "and\n#{decoded_routing_payload(actual_token)}\n" \
                             "to match\n#{ROUTING_PAYLOAD_REGEX}"
                         end
    end
  end

  matcher :have_different_random_bytes_than do |second_token|
    match do |first_token|
      decoded_random_bytes(first_token) != decoded_random_bytes(second_token)
    end

    chain :with_prefix do |prefix|
      @prefix = prefix
    end

    failure_message do |first_token|
      "Expected\n#{decoded_random_bytes(first_token)}\n" \
        "not to equal\n#{decoded_random_bytes(second_token)}"
    end
  end
end
