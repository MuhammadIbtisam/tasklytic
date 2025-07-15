class ApplicationController < ActionController::API
  respond_to :json

  def authenticate_user!
    super
  rescue Devise::JWT::RevocationStrategies::Denylist::RevokedToken
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
