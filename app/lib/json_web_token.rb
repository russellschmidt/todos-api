# app/lib/json_web_token.rb - define jwt singleton
class JsonWebToken
  # secret to encode and decode token based off the Rails app's unique secret key
  HMAC_SECRET = Rails.application.secrets.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    # set expiry to 24 hours from creation time
    payload[:exp] = exp.to_i
    # sign token with application secret
    JWT.encode(payload, HMAC_SECRET)
  end

  def self.decode(token)
    # get payload, first index in decoded array
    body = JWT.decode(token, HMAC_SECRET)[0]
    HashWithIndifferentAccess.new body
    #rescue from all decode errors
  rescue JWT::DecodeErrod => e
    # raise custom error to be handled by custom handler
    raise ExceptionHandler::InvalidToken, e.message
  end
end

module ExceptionHandler
  extend ActiveSupport::Concern

  class AuthenticationError < StandardError; end
  class MissingToken < StandardError; end
  class InvalidToken < StandardError; end

  included do
    rescue_from ActiveRecord::RecordInvalid, with: :four_twenty_two
    rescue_from ExceptionHandler::AuthenticationError, with: :unauthorized_request
    rescue_from ExceptionHandler::MissingToken, with: :four_twenty_two
    rescue_from ExceptionHandler::InvalidToken, with: :four_twenty_two
    rescue_from ActiveRecord::RecordNotFound do |e|
      json_response({ message: e.message }, :not_found)
    end
  end

private

# JSON response with message; Status code 422 - unprocessable entity
def four_twenty_two(e)
  json_response({ message: e.message}, :unprocessable_entity)
end

# JSON response with message; status code 401 - unauthorized
def unauthorized_request(e)
  json_response({ message: e.message }, :unauthorized)
end
end
