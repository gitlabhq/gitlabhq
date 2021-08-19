# frozen_string_literal: true

RSpec.shared_examples 'a service that handles Jira API errors' do
  include AfterNextHelpers
  using RSpec::Parameterized::TableSyntax

  where(:exception_class, :exception_message, :expected_message) do
    Errno::ECONNRESET | ''    | 'A connection error occurred'
    Errno::ECONNREFUSED | ''  | 'A connection error occurred'
    Errno::ETIMEDOUT | ''     | 'A timeout error occurred'
    Timeout::Error | ''       | 'A timeout error occurred'
    URI::InvalidURIError | '' | 'The Jira API URL'
    SocketError | ''          | 'The Jira API URL'
    OpenSSL::SSL::SSLError | 'foo'   | 'An SSL error occurred while connecting to Jira: foo'
    JIRA::HTTPError | 'Unauthorized' | 'The credentials for accessing Jira are not valid'
    JIRA::HTTPError | 'Forbidden'    | 'The credentials for accessing Jira are not allowed'
    JIRA::HTTPError | 'Bad Request'  | 'An error occurred while requesting data from Jira'
    JIRA::HTTPError | 'Foo'          | 'An error occurred while requesting data from Jira.'
    JIRA::HTTPError | '{"errorMessages":["foo","bar"]}' | 'An error occurred while requesting data from Jira: foo and bar'
    JIRA::HTTPError | '{"errorMessages":[""]}'          | 'An error occurred while requesting data from Jira.'
  end

  with_them do
    it 'handles the error' do
      stub_client_and_raise(exception_class, exception_message)

      expect(subject).to be_a(ServiceResponse)
      expect(subject).to be_error
      expect(subject.message).to include(expected_message)
    end
  end

  context 'when the JSON in JIRA::HTTPError is unsafe' do
    before do
      stub_client_and_raise(JIRA::HTTPError, error)
    end

    context 'when JSON is malformed' do
      let(:error) { '{"errorMessages":' }

      it 'returns the default error message' do
        expect(subject.message).to eq('An error occurred while requesting data from Jira. Check your Jira integration configuration and try again.')
      end
    end

    context 'when JSON contains tags' do
      let(:error) { '{"errorMessages":["<script>alert(true)</script>foo"]}' }

      it 'sanitizes it' do
        expect(subject.message).to eq('An error occurred while requesting data from Jira: foo. Check your Jira integration configuration and try again.')
      end
    end
  end

  it 'allows unknown exception classes to bubble' do
    stub_client_and_raise(StandardError)

    expect { subject }.to raise_exception(StandardError)
  end

  it 'logs the error' do
    stub_client_and_raise(Timeout::Error, 'foo')

    expect(Gitlab::ProjectServiceLogger).to receive(:error).with(
      hash_including(
        client_url: be_present,
        message: 'Error sending message',
        service_class: described_class.name,
        error: hash_including(
          exception_class: Timeout::Error.name,
          exception_message: 'foo',
          exception_backtrace: be_present
        )
      )
    )
    expect(subject).to be_error
  end

  def stub_client_and_raise(exception_class, message = '')
    # `JIRA::HTTPError` classes take a response from the JIRA API, rather than a `String`.
    message = double(body: message) if exception_class == JIRA::HTTPError

    allow_next(JIRA::Client).to receive(:get).and_raise(exception_class, message)
  end
end
