class ApplicationController < ActionController::API
  respond_to :json

  def authenticate_user!
    super
  rescue
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

private

def generate_jwt
  JWT.encode({ id: id, email: email }, Rails.application.credentials.secret_key_base, 'HS256')
end

def current_user
  @current_user ||= User.find(jwt_payload['id']) if jwt_payload
rescue StandardError
  nil
end

def jwt_payload
  @jwt_payload ||= JWT.decode(request.headers['Authorization'], Rails.application.credentials.secret_key_base, true, algorithm: 'HS256').first
rescue JWT::DecodeError
  nil
end

end
