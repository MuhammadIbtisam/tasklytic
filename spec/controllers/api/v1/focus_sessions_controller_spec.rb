require 'swagger_helper'

RSpec.describe Api::V1::FocusSessionsController, type: :controller do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:task) { create(:task, user: user, project: project) }
  let(:focus_session) { create(:focus_session, user: user, task: task) }

  before do
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    context 'with valid parameters' do
      it 'returns paginated focus sessions' do
        create_list(:focus_session, 15, user: user)
        
        get :index, params: { page: 1, per_page: 10 }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['focus_sessions'].length).to eq(10)
        expect(res['meta']['page']).to eq(1)
        expect(res['meta']['per_page']).to eq(10)
        expect(res['meta']['total']).to eq(15)
        expect(res['meta']['total_pages']).to eq(2)
      end

      it 'filters by task_id' do
        other_task = create(:task, user: user, project: project)
        create(:focus_session, user: user, task: task)
        create(:focus_session, user: user, task: other_task)
        
        get :index, params: { page: 1, task_id: task.id }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['focus_sessions'].length).to eq(1)
        expect(res['focus_sessions'].first['task_id']).to eq(task.id)
      end

      it 'filters by date range' do
        old_session = create(:focus_session, user: user, task: task, started_at: 2.weeks.ago)
        recent_session = create(:focus_session, user: user, task: task, started_at: 3.days.ago)
        
        get :index, params: { 
          page: 1, 
          start_date: 1.week.ago.to_date.to_s,
          end_date: Date.current.to_s
        }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['focus_sessions'].length).to eq(1)
        expect(res['focus_sessions'].first['id']).to eq(recent_session.id)
      end

      it 'filters by status' do
        active_session = create(:focus_session, user: user, task: task, ended_at: nil)
        completed_session = create(:focus_session, user: user, task: task, 
                                  started_at: 2.hours.ago, ended_at: 1.hour.ago)
        
        get :index, params: { page: 1, status: 'active' }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['focus_sessions'].length).to eq(1)
        expect(res['focus_sessions'].first['id']).to eq(active_session.id)
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
        create_list(:focus_session, 100, user: user)
        
        get :index, params: { page: 1, per_page: 100 }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['meta']['per_page']).to eq(50)
      end
    end

    context 'without authentication' do
      before do
        allow(controller).to receive(:authenticate_user!).and_raise(Devise::MissingWarden)
      end
      
      it 'returns unauthorized' do
        expect { get :index }.to raise_error(Devise::MissingWarden)
      end
    end
  end

  describe 'GET #show' do
    context 'with valid focus session' do
      it 'returns the focus session' do
        get :show, params: { id: focus_session.id }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['id']).to eq(focus_session.id)
        expect(res['task_id']).to eq(focus_session.task_id)
      end
    end

    context 'with non-existent focus session' do
      it 'returns not found' do
        get :show, params: { id: 99999 }
        
        expect(response).to have_http_status(:not_found)
        res = JSON.parse(response.body)
        expect(res['error']).to eq('Focus session not found')
      end
    end

    context 'with focus session belonging to another user' do
      let(:other_user) { create(:user) }
      let(:other_focus_session) { create(:focus_session, user: other_user) }
      
      it 'returns not found' do
        get :show, params: { id: other_focus_session.id }
        
        expect(response).to have_http_status(:not_found)
        res = JSON.parse(response.body)
        expect(res['error']).to eq('Focus session not found')
      end
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new focus session' do
        expect {
          post :create, params: { 
            focus_session: { 
              task_id: task.id, 
              notes: 'Starting focus session' 
            } 
          }
        }.to change { FocusSession.count }.by(1)
        
        expect(response).to have_http_status(:created)
        res = JSON.parse(response.body)
        expect(res['task_id']).to eq(task.id)
        expect(res['notes']).to eq('Starting focus session')
        expect(res['started_at']).to be_present
        expect(res['ended_at']).to be_nil
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        post :create, params: { 
          focus_session: { 
            task_id: nil,
            notes: 'Invalid session' 
          } 
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        res = JSON.parse(response.body)
        expect(res['errors']).to be_present
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid parameters' do
      it 'updates the focus session' do
        put :update, params: { 
          id: focus_session.id,
          focus_session: { 
            notes: 'Updated notes' 
          } 
        }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['notes']).to eq('Updated notes')
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        put :update, params: { 
          id: focus_session.id,
          focus_session: { 
            task_id: nil 
          } 
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        res = JSON.parse(response.body)
        expect(res['errors']).to be_present
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the focus session' do
      focus_session_id = focus_session.id
      expect {
        delete :destroy, params: { id: focus_session_id }
      }.to change { FocusSession.count }.by(-1)
      
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'PATCH #stop' do
    let(:active_focus_session) { create(:focus_session, user: user, task: task, ended_at: nil, started_at: 1.hour.ago) }
    
    context 'with active focus session' do
      it 'stops the focus session and calculates duration' do
        patch :stop, params: { id: active_focus_session.id }
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['ended_at']).to be_present
        expect(res['duration_minutes']).to be > 0
      end

      it 'updates user total focus time' do
        initial_focus_time = user.total_focus_time
        patch :stop, params: { id: active_focus_session.id }
        user.reload
        expect(user.total_focus_time).to be > initial_focus_time
      end
    end

    context 'with already ended focus session' do
      it 'returns error' do
        patch :stop, params: { id: focus_session.id }
        
        expect(response).to have_http_status(:unprocessable_entity)
        res = JSON.parse(response.body)
        expect(res['error']).to eq('Focus session already ended')
      end
    end
  end

  describe 'GET #current' do
    context 'with active focus session' do
      let!(:active_focus_session) { create(:focus_session, user: user, task: task, ended_at: nil) }
      
      it 'returns the active focus session' do
        get :current
        
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res['id']).to eq(active_focus_session.id)
        expect(res['ended_at']).to be_nil
      end
    end

    context 'without active focus session' do
      it 'returns not found message' do
        get :current
        
        expect(response).to have_http_status(:not_found)
        res = JSON.parse(response.body)
        expect(res['message']).to eq('No active focus session')
      end
    end
  end

  describe 'GET #stats' do
    let(:start_date) { 1.week.ago.to_date }
    let(:end_date) { Date.current }
    
    before do
      create(:focus_session, user: user, task: task, 
             started_at: 3.days.ago, ended_at: 2.days.ago, duration_minutes: 60)
      create(:focus_session, user: user, task: task, 
             started_at: 2.days.ago, ended_at: 1.day.ago, duration_minutes: 90)

      create(:focus_session, user: user, task: task, 
             started_at: 2.weeks.ago, ended_at: 2.weeks.ago, duration_minutes: 30)
    end

    it 'returns focus session statistics' do
      get :stats, params: { 
        start_date: start_date.to_s, 
        end_date: end_date.to_s 
      }
      
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)
      
      expect(res['total_duration_minutes']).to eq(150)
      expect(res['total_duration_hours']).to eq(2.5)
      expect(res['total_sessions']).to eq(2)
      expect(res['average_duration_minutes']).to eq(75.0)
      expect(res['period']['start_date']).to eq(start_date.to_s)
      expect(res['period']['end_date']).to eq(end_date.to_s)
      expect(res['daily_breakdown']).to be_present
      expect(res['task_breakdown']).to be_present
    end

    it 'uses default date range when not provided' do
      get :stats
      
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)
      expect(res['period']['start_date']).to eq(1.week.ago.to_date.to_s)
      expect(res['period']['end_date']).to eq(Date.current.to_s)
    end
  end
end
