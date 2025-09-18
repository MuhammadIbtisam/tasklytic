require 'swagger_helper'

RSpec.describe 'API::V1::Tasks', type: :request, swagger_doc: 'v1/swagger.yaml' do
  let(:user) { create(:user, password: 'password123') }
  let(:Authorization) { auth_headers_for_user(user)['Authorization'] }

  path 'api/v1/tasks' do
    get 'retreive_tasks' do
      tags 'Tasks'
      produces 'application/json'
      security [bearerAuth: []]
      parameter name: 'page', in: :query, type: :integer, required: true, description: 'Page Number'
      parameter name: 'per_page', in: :query, type: :integer, required: false, description: 'Per Page'
      parameter name: "status", in: :query, type: :integer, required: false, description: 'status'
      parameter name: 'project_id', in: :query, type: :integer, required: false, description: 'project id'
      parameter name: 'due_type', in: :query, type: :string, required: false, description: 'due type of projects such as overdue, due_today, due_this_week'

      response '400', 'Missing required Parameter: page' do
        let(:page) { nil }
        run_test! do |response|
          expect( JSON.parse(response.body)['error'] ).to eq('page parameter must be positive integer')
        end
      end

      response '400', 'page parameter must be positive' do
        let(:page) { -1 }
        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('page parameter must be positive integer')
        end
      end

      response '400', 'when page param is empty' do
        let(:page) { nil }
        run_test! do |response|
          expect( JSON.parse(response.body)['error']).to eq('page parameter must be positive integer')
        end
      end

      response '200', 'when tasks found' do
        let(:page) { 1 }
        let(:per_page) { 2 }
        before { create_list(:tasks, 5, user: user) }

        run_test! do |response|
          expect(response.status).to eq(200)
          res = JSON.parse(response.body)
          expect(res['tasks'].length).to eq(2)
          expect(res['meta']['total']).to eq(5)
          expect(res['meta']['total_pages']).to eq(3)
          expect(res['meta']['page']).to eq(1)
          expect(res['meta']['per_page']).to eq(2)
        end
      end

      response '200', 'when no tasks for user' do
        let(:page) { 1 }
        let(:per_page) { 2 }
        before { create_list(:tasks, 5) }

        run_test! do |response|
          expect(response.status).to eq(200)
          res = JSON.parse(response.body)
          expect(res['tasks'].length).to eq(0)
          expect(res['meta']['total']).to eq(0)
          expect(res['meta']['total_pages']).to eq(0)
        end
      end

      response '200', 'when no tasks found' do
        let(:page) { 1 }
        let(:per_page) { 2 }
        before { Task.delete_all }

        run_test! do |response|
          expect(response.status).to eq(200)
          res = JSON.parse(response.body)
          expect(res['tasks'].length).to eq(0)
          expect(res['meta']['total']).to eq(0)
          expect(res['meta']['total_pages']).to eq(0)
        end
      end


      response '200', 'Max per page cap' do
        let(:page) { 1 }
        let(:per_page) { 50 }
        before { create_list(:tasks, 30, user: user) }

        run_test! do |response|
          expect(response.status).to eq(200)
          res = JSON.parse(response.body)
          expect(res['tasks'].length).to eq(12)
          expect(res['meta']['total']).to eq(1)
          expect(res['meta']['total_pages']).to eq(3)
          expect(res['meta']['page']).to eq(1)
          expect(res['meta']['per_page']).to eq(12)
        end
      end

    end
  end
end