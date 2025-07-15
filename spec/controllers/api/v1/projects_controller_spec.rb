require 'rails_helper'

RSpec.describe Api::V1::ProjectsController, type: :controller do
  let(:user) { create(:user) }
  let(:valid_attributes) { { name: 'Test Project', description: 'Test Description' } }
  let(:invalid_attributes) { { name: '', description: 'Test Description' } }

  let(:jwt_headers) { auth_headers_for_test(user) }

  describe 'GET #index' do
    it 'returns a list of user projects' do
      project1 = create(:project, user: user)
      project2 = create(:project, user: user)
      other_user_project = create(:project, user: create(:user))

      request.headers.merge!(jwt_headers)
      get :index

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(2)
      expect(json_response.map { |p| p['id'] }).to match_array([project1.id, project2.id])
    end
  end

  describe 'GET #show' do
    it 'returns the requested project' do
      project = create(:project, user: user)

      request.headers.merge!(jwt_headers)
      get :show, params: { id: project.id }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(project.id)
      expect(json_response['name']).to eq(project.name)
    end

    it 'returns 404 for project not owned by user' do
      other_project = create(:project, user: create(:user))

      request.headers.merge!(jwt_headers)
      get :show, params: { id: other_project.id }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new project' do
        expect {
          request.headers.merge!(jwt_headers)
          post :create, params: { project: valid_attributes }
        }.to change(Project, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eq('Test Project')
        expect(json_response['user_id']).to eq(user.id)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a project' do
        expect {
          request.headers.merge!(jwt_headers)
          post :create, params: { project: invalid_attributes }
        }.not_to change(Project, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Name can't be blank")
      end
    end

    it 'enforces uniqueness of project name per user' do
      create(:project, user: user, name: 'Test Project')

      request.headers.merge!(jwt_headers)
      post :create, params: { project: valid_attributes }

      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to include('Name has already been taken')
    end
  end

  describe 'PUT #update' do
    let(:project) { create(:project, user: user) }

    context 'with valid parameters' do
      it 'updates the requested project' do
        request.headers.merge!(jwt_headers)
        put :update, params: { id: project.id, project: { name: 'Updated Project' } }

        expect(response).to have_http_status(:ok)
        project.reload
        expect(project.name).to eq('Updated Project')
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity status' do
        request.headers.merge!(jwt_headers)
        put :update, params: { id: project.id, project: invalid_attributes }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Name can't be blank")
      end
    end

    it 'returns 404 for project not owned by user' do
      other_project = create(:project, user: create(:user))

      request.headers.merge!(jwt_headers)
      put :update, params: { id: other_project.id, project: valid_attributes }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested project' do
      project = create(:project, user: user)

      expect {
        request.headers.merge!(jwt_headers)
        delete :destroy, params: { id: project.id }
      }.to change(Project, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for project not owned by user' do
      other_project = create(:project, user: create(:user))

      request.headers.merge!(jwt_headers)
      delete :destroy, params: { id: other_project.id }

      expect(response).to have_http_status(:not_found)
    end
  end
end