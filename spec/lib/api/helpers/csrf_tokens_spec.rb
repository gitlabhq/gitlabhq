require 'spec_helper'

describe API::Helpers do
  subject do
    Class.new.include(described_class).new
  end

  let(:header_token)  { 'WblCcheb1qQLHFVhlMtwOhxJr5613vUT05vCvToRvfJ68UPT7+eV5xpaY9CjubnF3VGbTfIhQYkZWmWTfvZAWQ==' }
  let(:session_token) { 'I0gBofh8Q0MRRjaxN3LJ/8EYNNNH/7SaysGnLkTn/as=' }

  before do
    class Request
      attr_reader :headers
      attr_reader :session

      def initialize(header_token = nil, session_token = nil)
        @headers = { 'X-Csrf-Token' => header_token  }
        @session = { '_csrf_token'  => session_token }
      end
    end
  end

  it 'should return false if header token is invalid' do
    request = Request.new(nil, session_token)
    expect(subject.send(:csrf_tokens_valid?, request)).to be false
  end

  it 'should return false if session_token token is invalid' do
    request = Request.new(header_token, nil)
    expect(subject.send(:csrf_tokens_valid?, request)).to be false
  end

  it 'should return false if header_token is not 64 symbols long' do
    request = Request.new(header_token[0..16], session_token)
    expect(subject.send(:csrf_tokens_valid?, request)).to be false
  end

  it 'should return true if both header_token and session_token are correct' do
    request = Request.new(header_token, session_token)
    expect(subject.send(:csrf_tokens_valid?, request)).to be true
  end
end
