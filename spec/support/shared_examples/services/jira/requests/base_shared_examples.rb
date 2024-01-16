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
    Gitlab::HTTP::BlockedUrlError | '' | 'Unable to connect to the Jira URL. Please verify your'
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
      expect(subject.message).to start_with(expected_message)
    end
  end

  context 'when the JSON in JIRA::HTTPError is unsafe' do
    config_docs_link_url = Rails.application.routes.url_helpers.help_page_path('integration/jira/configure')
    let(:docs_link_start) { '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: config_docs_link_url } }

    before do
      stub_client_and_raise(JIRA::HTTPError, error)
    end

    context 'when JSON is malformed' do
      let(:error) { '{"errorMessages":' }

      it 'returns the default error message' do
        error_message = 'An error occurred while requesting data from Jira. Check your %{docs_link_start}Jira integration configuration</a> and try again.' % { docs_link_start: docs_link_start }
        expect(subject.message).to eq(error_message)
      end
    end

    context 'when JSON contains tags' do
      let(:error) { '{"errorMessages":["<script>alert(true)</script>foo"]}' }

      it 'sanitizes it' do
        error_message = 'An error occurred while requesting data from Jira: foo. Check your %{docs_link_start}Jira integration configuration</a> and try again.' % { docs_link_start: docs_link_start }
        expect(subject.message).to eq(error_message)
      end
    end
  end

  it 'allows unknown exception classes to bubble' do
    stub_client_and_raise(StandardError)

    expect { subject }.to raise_exception(StandardError)
  end

  it 'logs the error' do
    stub_client_and_raise(Timeout::Error, 'foo')

    expect(jira_integration).to receive(:log_exception).with(
      kind_of(Timeout::Error),
      message: 'Error sending message',
      client_url: jira_integration.url
    )

    expect(subject).to be_error
  end

  def stub_client_and_raise(exception_class, message = '')
    # `JIRA::HTTPError` classes take a response from the JIRA API, rather than a `String`.
    message = double(body: message) if exception_class == JIRA::HTTPError

    allow_next(JIRA::Client).to receive(:get).and_raise(exception_class, message)
  end
end
