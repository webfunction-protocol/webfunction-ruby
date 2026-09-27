# frozen_string_literal: true

require "excon"
require "json"
require "uri"

require_relative "webfunction/version"
require_relative "webfunction/request"
require_relative "webfunction/page"
require_relative "webfunction/client"
require_relative "webfunction/flaggable"
require_relative "webfunction/package"
require_relative "webfunction/endpoint"
require_relative "webfunction/argument"
require_relative "webfunction/attribute"
require_relative "webfunction/object_schema"
require_relative "webfunction/documented_error"
require_relative "webfunction/pipeline"
require_relative "webfunction/promise"
require_relative "webfunction/type"
require_relative "webfunction/utils"

module WebFunction
  # A base error class for WebFunction. All errors inherit from this class.
  #
  # @api private
  #
  class Error < StandardError
    attr_reader :code, :details

    def initialize(message = nil, code: self.class.error_code, details: nil)
      super(message)
      @code = code
      @details = details
    end

    # Returns the error code for the error. Used as default error code if no code is provided.
    #
    # @return [String] The error code
    #
    def self.error_code
      name.sub(/^WebFunction::/, "WFN_")
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .upcase
    end
  end

  UnresolvedPromiseError = Class.new(Error)
  UnexpectedStatusCodeError = Class.new(Error)
  JsonParseError = Class.new(Error)
  BadRequestError = Class.new(Error)
end
