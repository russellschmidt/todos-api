# spec/auth/authorize_api_request_spec.rb
require 'rails_helper'

RSpec.describe AuthorizeApiRequest do
  let(:user) { create(:user) }
  # Mock authorization header
  let(:header) { { 'Authorization' => token_generator(user.id) } }
  # invalid request subject
  subject(:invalid_request_object) { described_class.new({}) }
  # valid request object
  subject(:request_obj) { described_class.new(header) }

  # Test suite for AuthorizeApiRequest#call
  # this is the point of entry into the service class
  describe '#call' do
    # returns user object when request is valid
    context 'when valid request' do
      it 'returns user object' do
        result = request_obj.call
        expect(result[:user]).to eq(user)
      end
    end

    # returns error message when invalid request
    context 'when invalid request' do
      context 'when missing token' do
        it 'raises a MissingToken error' do
          expect { invalid_request_obj.call }
            .to raise_error(ExceptionHander::MissingToken, 'Missing token')
        end
      end

      context 'when invalid token' do
        subject(:invalid_request_obj) do
          #custom helper method 'token generator'
          described_class.new('Authorization' => token_generator(5))
        end

        it 'raises an InvalidToken error' do
          expect { invalid_request_obj.call }
            .to raise_error(ExceptionHandler::InvalidToken, /InvalidToken/)
        end
      end

      context 'when token is expired' do 
        let(:header) { { 'Authorization' => expired_token_generator(user.id) } }
        subject(:request_obj) { described_class.new(header) }

        it 'raises ExceptionHandler::ExpiredSignature error' do
          expect { request_obj.call } 
            .to raise_error(
              ExceptionHandler::InvalidToken,
              /Signature has expired/
            )
        end
      end

      context 'fake token' do
        let(:header) { { 'Authorization' => 'foobar' } }
        subject(:invalid_request_obj) { described_class.new(header) }

        it 'handles JWT::DecodeError' do
          expect { invalid_request_obj.call }
            .to raise_error(
              ExceptionHandler::InvalidToken,
              /Not enough or too many segments/
            )
        end
      end
    end
  end
end

class AuthorizeApiRequest
  def initialize(headers = {})
    @headers = headers
  end

  # Service entry point - return valid user object
  def call 
    {
      user: user
    }
  end

  private

  attr_reader :headers

  def user
    # check if user is in the database 
    # memoize user object
    @user ||= User.find(decoded_auth_token[:user_id]) if decoded_auth_token
    # handle user not found
  rescue ActiveRecord::RecordNotFound => e
    # raise custom error
    raise (
      ExceptionHander::InvalidToken,
      ("#{Message.invalid_token} #{e.message}")
    )
  end

  # decode authentication token
  def decoded_auth_token
    @decoded_auth_token ||= JsonWebToken.decode(http_auth_header)
  end

  # check for token in 'Authorization' header
  def http_auth_header
    if headers['Authorization'].present?
      return headers['Authorization'].split(' ').last
    end
    raise(ExceptionHander::MissingToken, Message.missing_token)
  end
end