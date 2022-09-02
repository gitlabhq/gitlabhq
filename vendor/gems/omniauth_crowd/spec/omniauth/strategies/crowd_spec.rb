require 'spec_helper'

describe OmniAuth::Strategies::Crowd, :type=>:strategy do
  include OmniAuth::Test::StrategyTestCase
  def strategy
    @crowd_server_url ||= 'https://crowd.example.org'
    @application_name ||= 'bogus_app'
    @application_password ||= 'bogus_app_password'
    [OmniAuth::Strategies::Crowd, {:crowd_server_url => @crowd_server_url,
                                    :application_name => @application_name,
                                    :application_password => @application_password,
                                    :use_sessions => @using_sessions,
                                    :sso_url => @sso_url,
                                    :sso_url_image => @sso_url_image
     }]
  end

  @using_sessions = false
  @sso_url = nil
  @sso_url_image = nil
  let(:config) { OmniAuth::Strategies::Crowd::Configuration.new(strategy[1]) }
  let(:validator) { OmniAuth::Strategies::Crowd::CrowdValidator.new(config, 'foo', 'bar', nil, nil) }
  let(:csrf_token) { SecureRandom.base64(32) }
  let(:base_env) { { 'rack.session' => { csrf: csrf_token }, 'rack.input' => StringIO.new("authenticity_token=#{escaped_token}") } }
  let(:post_env) { make_env('/auth/crowd', base_env) }
  let(:escaped_token) { URI.encode_www_form_component(csrf_token, Encoding::UTF_8) }

  def make_env(path = '/auth/crowd', props = {})
    {
      'REQUEST_METHOD' => 'POST',
      'PATH_INFO' => path,
      'rack.session' => {},
      'rack.input' => StringIO.new('test=true')
    }.merge(props)
  end

  describe 'Authentication Request Body' do
    it 'should send password in session request' do
      body = <<-BODY.strip
<password>
  <value>bar</value>
</password>
BODY
      expect(validator.send(:make_authentication_request_body, 'bar')).to eq(body)
    end

    it 'should escape special characters username and password in session request' do
      body = <<-BODY.strip
<password>
  <value>bar&lt;</value>
</password>
BODY
      expect(validator.send(:make_authentication_request_body, 'bar<')).to eq(body)
    end
  end

  describe 'POST /auth/crowd' do
    it 'should show the login form' do
      post '/auth/crowd', nil, post_env
      expect(last_response).to be_ok
    end
  end

  describe 'GET /auth/crowd/callback without any credentials' do
    it 'should fail' do
      get '/auth/crowd/callback'
      expect(last_response).to be_redirect
      expect(last_response.headers['Location']).to match(/no_credentials/)
    end
  end

  describe 'GET /auth/crowd/callback with credentials can be successful' do
    context "when using authentication endpoint" do
      before do
        stub_request(:post, "https://crowd.example.org/rest/usermanagement/latest/authentication?username=foo").
        to_return(:body => File.read(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'success.xml')))

        stub_request(:get, "https://crowd.example.org/rest/usermanagement/latest/user/group/direct?username=foo").
            to_return(:body => File.read(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'groups.xml')))

        #Adding this to prevent Content-Type text/xml from being added back in the future
        stub_request(:get, "https://crowd.example.org/rest/usermanagement/latest/user/group/direct?username=foo").with(:headers => {"Content-Type" => "text/xml"}).
            to_return(:status => [415, "Unsupported Media Type"])
        get '/auth/crowd/callback', nil, 'rack.session'=>{'omniauth.crowd'=> {"username"=>"foo", "password"=>"ba"}}
      end

      it 'should call through to the master app' do
        expect(last_response.body).to eq('true')
      end

      it 'should have an auth hash' do
        auth = last_request.env['omniauth.auth']
        expect(auth).to be_kind_of(Hash)
      end

      it 'should have good data' do
        auth = last_request.env['omniauth.auth']
        expect(auth['provider']).to eq(:crowd)
        expect(auth['uid']).to eq('foo')
        expect(auth['info']).to be_kind_of(Hash)
        expect(auth['info']['groups'].sort).to eq(["Developers", "jira-users"].sort)
      end
    end

    describe "when using session endpoint" do
      before do
        @using_sessions = true
        stub_request(:post, "https://crowd.example.org/rest/usermanagement/latest/authentication?username=foo").
          to_return(:body => File.read(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'success.xml')))
        stub_request(:post, "https://crowd.example.org/rest/usermanagement/latest/session").
          to_return(:status => 201, :body => File.read(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'session.xml')))
        stub_request(:get, "https://crowd.example.org/rest/usermanagement/latest/user/group/direct?username=foo").
          to_return(:body => File.read(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'groups.xml')))
      end

      after { @using_sessions = false }

      it 'should call through to the master app' do
        get '/auth/crowd/callback', nil, 'rack.session'=>{'omniauth.crowd'=> {"username"=>"foo", "password"=>"ba"}}
        expect(last_response.body).to eq('true')
      end

      it 'should have an auth hash' do
        get '/auth/crowd/callback', nil, 'rack.session'=>{'omniauth.crowd'=> {"username"=>"foo", "password"=>"ba"}}
        expect(last_request.env['omniauth.auth']).to be_kind_of(Hash)
      end

      it 'should have good data' do
        get '/auth/crowd/callback', nil, 'rack.session'=>{'omniauth.crowd'=> {"username"=>"foo", "password"=>"ba"}}
        auth = last_request.env['omniauth.auth']
        expect(auth['provider']).to eq(:crowd)
        expect(auth['uid']).to eq('foo')
        expect(auth['info']).to be_kind_of(Hash)
        expect(auth['info']['sso_token']).to eq('rtk8eMvqq00EiGn5iJCMZQ00')
        expect(auth['info']['groups'].sort).to eq(["Developers", "jira-users"].sort)
      end
    end
  end

  describe 'GET /auth/crowd/callback with credentials will fail' do
    before do
      stub_request(:post, "https://crowd.example.org/rest/usermanagement/latest/authentication?username=foo").
      to_return(:status=>400)
      get '/auth/crowd/callback', nil, 'rack.session'=>{'omniauth.crowd'=> {"username"=>"foo", "password"=>"ba"}}
    end
    it 'should fail' do
      expect(last_response).to be_redirect
      expect(last_response.headers['Location']).to match(/invalid_credentials/)
    end
  end

  describe 'POST /auth/crowd without credentials will redirect to login form' do
    sso_url = 'https://foo.bar'

    before do
      @using_sessions = true
      @sso_url = sso_url
    end

    it 'should have the SSO button in the response body' do
      found_legend = found_anchor = nil

      post '/auth/crowd', nil, post_env

      Nokogiri::HTML(last_response.body).xpath('//html/body/form/fieldset/*').each do |element|

        if element.name === 'legend' && element.content() === 'SSO'
          found_legend = true
        elsif element.name === 'a' && element.attr('href') === "#{sso_url}/users/auth/crowd/callback"
          found_anchor = true
        end
      end

      expect(found_legend).to(be(true))
      expect(found_anchor).to(be(true))
    end

    after do
      @using_sessions = false
      @sso_url = nil
    end
  end

  describe 'POST /auth/crowd without credentials will redirect to login form which has custom image in the SSO link' do
    sso_url = 'https://foo.bar'
    sso_url_image = 'https://foo.bar/image.png'

    before do
      @using_sessions = true
      @sso_url = sso_url
      @sso_url_image = 'https://foo.bar/image.png'
    end

    it 'should have the SSO button with a custom image in the response body' do
      found_legend = found_anchor = found_image = false

      post '/auth/crowd', nil, post_env

      Nokogiri::HTML(last_response.body).xpath('//html/body/form/fieldset/*').each do |element|

        if element.name === 'legend' && element.content() === 'SSO'
          found_legend = true
        elsif element.name === 'a' && element.attr('href') === "#{sso_url}/users/auth/crowd/callback"

          found_anchor = true

          if element.children.length === 1 && element.children.first.name === 'img' && element.children.first.attr('src') === sso_url_image
            found_image = true
          end
        end
      end

      expect(found_legend).to(be(true))
      expect(found_anchor).to(be(true))
      expect(found_image).to(be(true))
    end

    after do
      @using_sessions = false
      @sso_url = nil
      @sso_url_image = nil
    end
  end

  describe 'POST /auth/crowd/callback without credentials but with SSO cookie will redirect to login form because session is invalid' do
    sso_url = 'https://foo.bar'
    token = 'foobar'

    before do
      @using_sessions = true
      @sso_url = sso_url

      stub_request(:get, "https://crowd.example.org/rest/usermanagement/latest/session/#{token}").
          to_return(:status => [404])

      set_cookie("crowd.token_key=#{token}")
    end

    it 'should redirect to login form' do
      post '/auth/crowd/callback'
      expect(last_response).to be_redirect
      expect(last_response.headers['Location']).to match(/invalid_credentials/)
    end

    after do

      @using_sessions = false
      @sso_url = nil

      clear_cookies()

    end

  end
  
  describe 'GET /auth/crowd/callback without credentials but with SSO cookie will succeed' do

    sso_url = 'https://foo.bar'
    token = 'rtk8eMvqq00EiGn5iJCMZQ00'
    
    before do
      
      @using_sessions = true
      @sso_url = sso_url

      stub_request(:get, "https://crowd.example.org/rest/usermanagement/latest/session/#{token}").
        to_return(:status => 200, :body => File.read(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'session.xml')))
      stub_request(:post, "https://crowd.example.org/rest/usermanagement/latest/session/#{token}").
        to_return(:status => 200)
      stub_request(:get, "https://crowd.example.org/rest/usermanagement/latest/user/group/direct?username=foo").
        to_return(:body => File.read(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'groups.xml')))
      
      set_cookie("crowd.token_key=#{token}")

    end

    it 'should return user data' do

      auth = nil

      get '/auth/crowd/callback'

      auth = last_request.env['omniauth.auth']

      expect(auth['provider']).to eq(:crowd)
      expect(auth['uid']).to eq('foo')
      expect(auth['info']).to be_kind_of(Hash)
      expect(auth['info']['groups'].sort).to eq(["Developers", "jira-users"].sort)

    end

    after do

      @using_sessions = false
      @sso_url = nil

      clear_cookies()

    end

  end

  describe 'GET /auth/crowd/callback without credentials but with multiple SSO cookies will succeed because one of them is valid' do

    sso_url = 'https://foo.bar'
    
    before do
      
      @using_sessions = true
      @sso_url = sso_url

      stub_request(:get, "https://crowd.example.org/rest/usermanagement/latest/session/foo").
        to_return(:status => 404)
      stub_request(:get, "https://crowd.example.org/rest/usermanagement/latest/session/fubar").
        to_return(:status => 404)
      stub_request(:get, "https://crowd.example.org/rest/usermanagement/latest/session/rtk8eMvqq00EiGn5iJCMZQ00").
        to_return(:status => 200, :body => File.read(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'session.xml')))
      stub_request(:post, "https://crowd.example.org/rest/usermanagement/latest/session/rtk8eMvqq00EiGn5iJCMZQ00").
        to_return(:status => 200)
      stub_request(:get, "https://crowd.example.org/rest/usermanagement/latest/user/group/direct?username=foo").
        to_return(:body => File.read(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'groups.xml')))

      header('Cookie', "crowd.token_key=foo;crowd.token_key=rtk8eMvqq00EiGn5iJCMZQ00;crowd.token_key=fubar")

    end

    it 'should return user data' do
      auth = nil

      get '/auth/crowd/callback'

      auth = last_request.env['omniauth.auth']

      expect(auth['provider']).to eq(:crowd)
      expect(auth['uid']).to eq('foo')
      expect(auth['info']).to be_kind_of(Hash)
      expect(auth['info']['groups'].sort).to eq(["Developers", "jira-users"].sort)

    end

    after do

      @using_sessions = false
      @sso_url = nil

      header('Cookie', nil)

    end

  end
end
