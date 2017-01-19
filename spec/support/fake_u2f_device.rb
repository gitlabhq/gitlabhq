class FakeU2fDevice
  attr_reader :name

  def initialize(page, name)
    @page = page
    @name = name
  end

  def respond_to_u2f_registration
    app_id = @page.evaluate_script('gon.u2f.app_id')
    challenges = @page.evaluate_script('gon.u2f.challenges')

    json_response = u2f_device(app_id).register_response(challenges[0])

    @page.execute_script("
    u2f.register = function(appId, registerRequests, signRequests, callback) {
      callback(#{json_response});
    };
    ")
  end

  def respond_to_u2f_authentication
    app_id = @page.evaluate_script('gon.u2f.app_id')
    challenge = @page.evaluate_script('gon.u2f.challenge')
    json_response = u2f_device(app_id).sign_response(challenge)

    @page.execute_script("
    u2f.sign = function(appId, challenges, signRequests, callback) {
      callback(#{json_response});
    };
    window.gl.u2fAuthenticate.start();
    ")
  end

  private

  def u2f_device(app_id)
    @u2f_device ||= U2F::FakeU2F.new(app_id)
  end
end
