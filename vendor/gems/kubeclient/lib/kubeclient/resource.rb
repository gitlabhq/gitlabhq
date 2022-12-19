require 'recursive_open_struct'

module Kubeclient
  # Represents all the objects returned by Kubeclient
  class Resource < RecursiveOpenStruct
    def initialize(hash = nil, args = {})
      args[:recurse_over_arrays] = true
      super(hash, args)
    end
  end
end
