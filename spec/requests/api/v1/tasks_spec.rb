require 'swagger_helper'

RSpec.describe "API::V1::Tasks", swagger_doc: 'v1/swagger.yaml' do
  let(:user) { create(:user, password: 'password123') }
  let(:Authorization) { auth_headers_for_user(user)['Authorization'] }

  path '/api/v1/tasks' do
    get 'retrieve tasks' do
      tags 'Tasks'
      produces 'application/json'
      security [bearerAuth: []]
      parameter name: 'page', in: :query, type: :integer, required: true, description: 'Page number'
      parameter name: 'per_page', in: :query, type: :integer, required: false, description: 'Per page'
      parameter project_id: 'Project Id', in: :query, type: :integer, required: false, description: 'Project id of the tasks'

      response "200", 'tasks in descending order when project id is not given' do
        let(:page) { 1 }
        let(:per_page) { 5 }
        before { create_list(:task, 10) }

        run_test! do |response|
          res = JSON.parse(response.body)
          expect(res['tasks'].length).to eq(5)
        end
      end
    end
  end
end