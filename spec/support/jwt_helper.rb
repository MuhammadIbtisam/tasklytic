module JwtHelper
  def generate_jwt_token(user)
    user.jti ||= SecureRandom.uuid
    user.save! if user.changed?
    payload = {
      sub: user.id,
      iat: Time.current.to_i,
      exp: 30.minutes.from_now.to_i,
      jti: user.jti,
      scp: 'user'
    }
    JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
  end

  def auth_headers_for_test(user)
    { 'Authorization' => "Bearer #{generate_jwt_token(user)}" }
  end

  def auth_headers_for_user(user)
    # For Rails 8 compatibility, use direct JWT generation instead of session-based auth
    { 'Authorization' => "Bearer #{generate_jwt_token(user)}" }
  end
end

RSpec.configure do |config|
  config.include JwtHelper
end 