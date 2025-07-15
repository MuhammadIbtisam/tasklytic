require 'rails_helper'

RSpec.describe 'JWT Auth', type: :request do
  let(:user) { create(:user, password: 'password123') }
  let(:jwt) { generate_jwt_token(user) }
  let(:headers) { { 'Authorization' => "Bearer #{jwt}", 'Accept' => 'application/json' } }

  it 'returns 200 for authenticated request' do
    get '/api/v1/projects', headers: headers
    puts "DEBUG: response status: ", response.status
    puts "DEBUG: response body: ", response.body
    expect(response).not_to have_http_status(:unauthorized)
  end
end 