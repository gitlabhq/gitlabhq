# frozen_string_literal: true

module TrackingHelpers
  def stub_do_not_track(value)
    request.headers['DNT'] = value
  end
end
