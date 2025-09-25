require 'swagger_helper'

RSpec.describe Api::V1::TagsController, type: :controller do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:task) { create(:task, user: user, project: project) }
  let(:tag) { create(:tag, name: 'test-tag') }
  let(:other_user) { create(:user) }
  let(:other_task) { create(:task, user: other_user, project: create(:project, user: other_user)) }

  before do
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    context 'with valid parameters' do
      it 'returns paginated tags' do
        15.times { |i| create(:tag, name: "tag-#{i}") }
        
        get :index, params: { page: 1, per_page: 10 }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['tags'].length).to eq(10)
        expect(res['meta']['page']).to eq(1)
        expect(res['meta']['per_page']).to eq(10)
        expect(res['meta']['total']).to eq(15)
        expect(res['meta']['total_pages']).to eq(2)
      end

      it 'filters by search term' do
        create(:tag, name: 'ruby')
        create(:tag, name: 'rails')
        create(:tag, name: 'javascript')
        
        get :index, params: { page: 1, search: 'ruby' }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['tags'].length).to eq(1)
        expect(res['tags'].first['name']).to eq('ruby')
      end

      it 'filters by user only' do
        user_tag = create(:tag, name: 'user-tag')
        other_tag = create(:tag, name: 'other-tag')
        create(:task_tag, task: task, tag: user_tag)
        create(:task_tag, task: other_task, tag: other_tag)
        
        get :index, params: { page: 1, user_only: 'true' }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['tags'].length).to eq(1)
        expect(res['tags'].first['name']).to eq('user-tag')
      end

      it 'sorts by usage count' do
        popular_tag = create(:tag, name: 'popular')
        less_popular_tag = create(:tag, name: 'less-popular')

        3.times do |i|
          task_i = create(:task, user: user, project: project)
          create(:task_tag, task: task_i, tag: popular_tag)
        end
        create(:task_tag, task: task, tag: less_popular_tag)
        
        get :index, params: { page: 1, sort: 'usage_count' }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['tags'].first['name']).to eq('popular')
      end
    end

    context 'with invalid parameters' do
      it 'returns error for invalid page parameter' do
        get :index, params: { page: 0 }
        
        expect(response).to have_http_status(:bad_request)
        res = JSON.parse(response.body)
        expect(res['error']).to eq('page parameter must be positive integer')
      end

      it 'caps per_page at maximum of 50' do
        100.times { |i| create(:tag, name: "tag-#{i}") }
        
        get :index, params: { page: 1, per_page: 100 }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['meta']['per_page']).to eq(50)
      end
    end
  end

  describe 'GET #show' do
    context 'with valid tag' do
      it 'returns the tag with usage count and tasks' do
        create(:task_tag, task: task, tag: tag)
        
        get :show, params: { id: tag.id }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['tag']['id']).to eq(tag.id)
        expect(res['tag']['name']).to eq(tag.name)
        expect(res['usage_count']).to eq(1)
        expect(res['tasks']).to be_an(Array)
      end
    end

    context 'with non-existent tag' do
      it 'returns not found' do
        get :show, params: { id: 99999 }
        
        expect(response).to have_http_status(:not_found)
        res = JSON.parse(response.body)
        expect(res['error']).to eq('Tag not found')
      end
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new tag' do
        expect {
          post :create, params: { tag: { name: 'new-tag' } }
        }.to change { Tag.count }.by(1)
        
        expect(response).to have_http_status(:created)
        res = JSON.parse(response.body)
        expect(res['name']).to eq('new-tag')
      end

      it 'returns existing tag if already exists' do
        existing_tag = create(:tag, name: 'existing-tag')
        
        post :create, params: { tag: { name: 'existing-tag' } }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['message']).to eq('Tag already exists')
        expect(res['tag']['id']).to eq(existing_tag.id)
      end

      it 'downcases tag name' do
        post :create, params: { tag: { name: 'UPPERCASE-TAG' } }
        
        expect(response).to have_http_status(:created)
        res = JSON.parse(response.body)
        expect(res['name']).to eq('uppercase-tag')
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        post :create, params: { tag: { name: nil } }
        
        expect(response).to have_http_status(:unprocessable_entity)
        res = JSON.parse(response.body)
        expect(res['errors']).to be_present
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid parameters' do
      it 'updates the tag' do
        put :update, params: { id: tag.id, tag: { name: 'updated-tag' } }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['name']).to eq('updated-tag')
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        put :update, params: { id: tag.id, tag: { name: nil } }
        
        expect(response).to have_http_status(:unprocessable_entity)
        res = JSON.parse(response.body)
        expect(res['errors']).to be_present
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'with tag not assigned to tasks' do
      it 'deletes the tag' do
        tag_id = tag.id
        expect {
          delete :destroy, params: { id: tag_id }
        }.to change { Tag.count }.by(-1)
        
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'with tag assigned to tasks' do
      it 'returns error and does not delete' do
        create(:task_tag, task: task, tag: tag)
        
        expect {
          delete :destroy, params: { id: tag.id }
        }.not_to change { Tag.count }
        
        expect(response).to have_http_status(:unprocessable_entity)
        res = JSON.parse(response.body)
        expect(res['error']).to include('Cannot delete tag that is assigned to tasks')
      end
    end
  end

  describe 'GET #popular' do
    it 'returns most used tags by current user' do
      popular_tag = create(:tag, name: 'popular')
      less_popular_tag = create(:tag, name: 'less-popular')
      
      # Create different tasks for each tag association
      3.times do |i|
        task_i = create(:task, user: user, project: project)
        create(:task_tag, task: task_i, tag: popular_tag)
      end
      create(:task_tag, task: task, tag: less_popular_tag)
      
      get :popular, params: { limit: 5 }
      
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)
      expect(res['popular_tags'].length).to eq(2)
      expect(res['popular_tags'].first['name']).to eq('popular')
      expect(res['popular_tags'].first['usage_count']).to eq(3)
    end

    it 'respects limit parameter' do
      15.times do |i|
        tag = create(:tag, name: "tag-#{i}")
        (i + 1).times do |j|
          task_j = create(:task, user: user, project: project)
          create(:task_tag, task: task_j, tag: tag)
        end
      end
      
      get :popular, params: { limit: 5 }
      
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)
      expect(res['popular_tags'].length).to eq(5)
    end
  end

  describe 'GET #for_task' do
    it 'returns tags for a specific task' do
      tag1 = create(:tag, name: 'tag1')
      tag2 = create(:tag, name: 'tag2')
      
      task.tags = [tag1, tag2]
      
      get :for_task, params: { task_id: task.id }
      
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)
      expect(res.length).to eq(2)
      expect(res.map { |t| t['name'] }).to contain_exactly('tag1', 'tag2')
    end

    it 'returns not found for non-existent task' do
      get :for_task, params: { task_id: 99999 }
      
      expect(response).to have_http_status(:not_found)
      res = JSON.parse(response.body)
      expect(res['error']).to eq('Task not found')
    end
  end

  describe 'POST #assign_to_task' do
    it 'assigns tags to a task' do
      tag1 = create(:tag, name: 'tag1')
      tag2 = create(:tag, name: 'tag2')
      
      post :assign_to_task, params: { 
        task_id: task.id, 
        tag_names: ['tag1', 'tag2', 'new-tag'] 
      }
      
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)
      expect(res['message']).to eq('Tags assigned successfully')
      expect(res['tags'].length).to eq(3)
      expect(task.reload.tags.count).to eq(3)
    end

    it 'creates new tags if they do not exist' do
      expect {
        post :assign_to_task, params: { 
          task_id: task.id, 
          tag_names: ['new-tag1', 'new-tag2'] 
        }
      }.to change { Tag.count }.by(2)
      
      expect(response).to have_http_status(:ok)
    end

    it 'returns not found for non-existent task' do
      post :assign_to_task, params: { 
        task_id: 99999, 
        tag_names: ['tag1'] 
      }
      
      expect(response).to have_http_status(:not_found)
      res = JSON.parse(response.body)
      expect(res['error']).to eq('Task not found')
    end
  end

  describe 'DELETE #remove_from_task' do
    it 'removes tags from a task' do
      tag1 = create(:tag, name: 'tag1')
      tag2 = create(:tag, name: 'tag2')
      task.tags = [tag1, tag2]
      
      delete :remove_from_task, params: { 
        task_id: task.id, 
        tag_ids: [tag1.id] 
      }
      
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)
      expect(res['message']).to eq('Tags removed successfully')
      expect(task.reload.tags.count).to eq(1)
      expect(task.tags.first.name).to eq('tag2')
    end

    it 'returns not found for non-existent task' do
      delete :remove_from_task, params: { 
        task_id: 99999, 
        tag_ids: [1] 
      }
      
      expect(response).to have_http_status(:not_found)
      res = JSON.parse(response.body)
      expect(res['error']).to eq('Task not found')
    end
  end

  describe 'GET #stats' do
    it 'returns tag statistics for current user' do
      tag1 = create(:tag, name: 'tag1')
      tag2 = create(:tag, name: 'tag2')
      unused_tag = create(:tag, name: 'unused')
      
      3.times do |i|
        task_i = create(:task, user: user, project: project)
        create(:task_tag, task: task_i, tag: tag1)
      end
      create(:task_tag, task: task, tag: tag2)
      
      get :stats
      
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)
      expect(res['total_tags_used']).to eq(2)
      expect(res['most_used_tag']['name']).to eq('tag1')
      expect(res['most_used_tag']['usage_count']).to eq(3)
      expect(res['unused_tags_count']).to eq(1)
    end
  end
end
