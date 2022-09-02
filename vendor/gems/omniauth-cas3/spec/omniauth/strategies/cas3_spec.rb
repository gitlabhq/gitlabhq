require 'spec_helper'
require 'securerandom'

describe OmniAuth::Strategies::CAS3, type: :strategy do
  include Rack::Test::Methods

  let(:my_cas_provider) { Class.new(OmniAuth::Strategies::CAS3) }
  before do
    stub_const 'MyCasProvider', my_cas_provider
  end
  let(:app) do
    Rack::Builder.new {
      use OmniAuth::Test::PhonySession
      use MyCasProvider, name: :cas3, host: 'cas.example.org', ssl: false, port: 8080, uid_field: :employeeid
      run lambda { |env| [404, {'Content-Type' => 'text/plain'}, [env.key?('omniauth.auth').to_s]] }
    }.to_app
  end

  let(:csrf_token) { SecureRandom.base64(32) }
  let(:base_env) { { 'rack.session' => { csrf: csrf_token }, 'rack.input' => StringIO.new("authenticity_token=#{escaped_token}") } }
  let(:post_env) { make_env('/auth/cas3', base_env.merge(request_env)) }
  let(:escaped_token) { URI.encode_www_form_component(csrf_token, Encoding::UTF_8) }

  def make_env(path = '/auth/cas3', props = {})
    {
      'REQUEST_METHOD' => 'POST',
      'PATH_INFO' => path,
      'rack.session' => {},
      'rack.input' => StringIO.new('test=true')
    }.merge(props)
  end

  # TODO: Verify that these are even useful tests
  shared_examples_for 'a CAS redirect response' do
    let(:redirect_params) { 'service=' + Rack::Utils.escape("http://example.org/auth/cas3/callback?url=#{Rack::Utils.escape(return_url)}") }

    before { post url, nil, post_env }

    subject { last_response }

    it { should be_redirect }

    it 'redirects to the CAS server' do
      expect(subject.status).to eq(302)
      expect(subject.headers).to include 'Location' => "http://cas.example.org:8080/login?#{redirect_params}"
    end
  end

  describe '#cas_url' do
    let(:params) { Hash.new }
    let(:provider) { MyCasProvider.new(nil, params) }

    subject { provider.cas_url }

    it 'raises an ArgumentError' do
      expect{subject}.to raise_error ArgumentError, %r{:host and :login_url MUST be provided}
    end

    context 'with an explicit :url option' do
      let(:url) { 'https://example.org:8080/my_cas' }
      let(:params) { super().merge url:url }

      before { subject }

      it { should eq url }

      it 'parses the URL into it the appropriate strategy options' do
        expect(provider.options).to include ssl:true
        expect(provider.options).to include host:'example.org'
        expect(provider.options).to include port:8080
        expect(provider.options).to include path:'/my_cas'
      end
    end

    context 'with explicit URL component' do
      let(:params) { super().merge host:'example.org', port:1234, ssl:true, path:'/a/path' }

      before { subject }

      it { should eq 'https://example.org:1234/a/path' }

      it 'parses the URL into it the appropriate strategy options' do
        expect(provider.options).to include ssl:true
        expect(provider.options).to include host:'example.org'
        expect(provider.options).to include port:1234
        expect(provider.options).to include path:'/a/path'
      end
    end
  end

  describe 'defaults' do
    subject { MyCasProvider.default_options.to_hash }

    it { should include('ssl' => true) }
  end

  describe 'POST /auth/cas3' do
    let(:return_url) { 'http://myapp.com/admin/foo' }

    context 'with a referer' do
      let(:url) { '/auth/cas3' }

      let(:request_env) { { 'HTTP_REFERER' => return_url } }

      it_behaves_like 'a CAS redirect response'
    end

    context 'with an explicit return URL' do
      let(:url) { "/auth/cas3?url=#{return_url}" }

      let(:request_env) { {} }

      it_behaves_like 'a CAS redirect response'
    end
  end

  describe 'GET /auth/cas3/callback' do
    context 'without a ticket' do
      before { get '/auth/cas3/callback' }

      subject { last_response }

      it { should be_redirect }

      it 'redirects with a failure message' do
        expect(subject.headers).to include 'Location' => '/auth/failure?message=no_ticket&strategy=cas3'
      end
    end

    context 'with an invalid ticket' do
      before do
        stub_request(:get, /^http:\/\/cas.example.org:8080?\/p3\/serviceValidate\?([^&]+&)?ticket=9391d/).
           to_return( body: File.read('spec/fixtures/cas_failure.xml') )
        get '/auth/cas3/callback?ticket=9391d'
      end

      subject { last_response }

      it { should be_redirect }

      it 'redirects with a failure message' do
        expect(subject.headers).to include 'Location' => '/auth/failure?message=invalid_ticket&strategy=cas3'
      end
    end

    describe 'with a valid ticket' do
      shared_examples :successful_validation do
        before do
          stub_request(:get, /^http:\/\/cas.example.org:8080?\/p3\/serviceValidate\?([^&]+&)?ticket=593af/)
            .with { |request| @request_uri = request.uri.to_s }
            .to_return( body: File.read("spec/fixtures/#{xml_file_name}") )

          get "/auth/cas3/callback?ticket=593af&url=#{return_url}"
        end

        it 'strips the ticket parameter from the callback URL' do
          expect(@request_uri.scan('ticket=').size).to eq 1
        end

        it 'properly encodes the service URL' do
          expect(WebMock).to have_requested(:get, 'http://cas.example.org:8080/p3/serviceValidate')
            .with(query: {
              ticket:  '593af',
              service: 'http://example.org/auth/cas3/callback?url=' + Rack::Utils.escape('http://127.0.0.10/?some=parameter')
            })
        end

        context "request.env['omniauth.auth']" do
          subject { last_request.env['omniauth.auth'] }

          it { should be_kind_of Hash }

          it 'identifes the provider' do
            expect(subject.provider).to eq :cas3
          end

          it 'returns the UID of the user' do
            expect(subject.uid).to eq '54'
          end

          context 'the info hash' do
            subject { last_request.env['omniauth.auth']['info'] }

            it 'includes user info attributes' do
              expect(subject.name).to eq 'Peter Segel'
              expect(subject.first_name).to eq 'Peter'
              expect(subject.last_name).to eq 'Segel'
              expect(subject.nickname).to eq 'psegel'
              expect(subject.email).to eq 'psegel@intridea.com'
              expect(subject.location).to eq 'Washington, D.C.'
              expect(subject.image).to eq '/images/user.jpg'
              expect(subject.phone).to eq '555-555-5555'
            end
          end

          context 'the extra hash' do
            subject { last_request.env['omniauth.auth']['extra'] }

            it 'includes additional user attributes' do
              expect(subject.user).to eq 'psegel'
              expect(subject.employeeid).to eq '54'
              expect(subject.hire_date).to eq '2004-07-13'
            end
          end

          context 'the credentials hash' do
            subject { last_request.env['omniauth.auth']['credentials'] }

            it 'has a ticket value' do
              expect(subject.ticket).to eq '593af'
            end
          end
        end

        it 'calls through to the master app' do
          expect(last_response.body).to eq 'true'
        end
      end

      let(:return_url) { 'http://127.0.0.10/?some=parameter' }

      context 'with JASIG flavored XML' do
        let(:xml_file_name) { 'cas_success_jasig.xml' }

        it_behaves_like :successful_validation
      end

      context 'with classic XML' do
        let(:xml_file_name) { 'cas_success.xml' }

        it_behaves_like :successful_validation
      end
    end
  end

  describe 'POST /auth/cas3/callback' do
    describe 'with a Single Sign-Out logoutRequest' do
      let(:logoutRequest) do
        %Q[
          <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion\" ID="123abc-1234-ab12-cd34-1234abcd" Version="2.0" IssueInstant="#{Time.now.to_s}">
            <saml:NameID>@NOT_USED@</saml:NameID>
            <samlp:SessionIndex>ST-123456-123abc456def</samlp:SessionIndex>
          </samlp:LogoutRequest>
        ]
      end

      let(:logout_request) { double('logout_request', call:[200,{},'OK']) }

      subject do
        post 'auth/cas3/callback', logoutRequest:logoutRequest
      end

      before do
        allow_any_instance_of(MyCasProvider)
          .to receive(:logout_request_service)
          .and_return double('LogoutRequest', new:logout_request)

        subject
      end

      it 'initializes a LogoutRequest' do
        expect(logout_request).to have_received :call
      end
    end
  end
end
