# frozen_string_literal: true

app = proc do |env|
  if env['REQUEST_METHOD'] == 'GET'
    [200, {}, [Process.pid.to_s]]
  else
    Process.kill(env['QUERY_STRING'], Process.pid)
    [200, {}, ['Bye!']]
  end
end

run app
