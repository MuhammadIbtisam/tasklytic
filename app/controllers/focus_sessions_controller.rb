class FocusSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_focus_session, only: [:show, :update, :destroy]

  def index
    @focus_sessions = current_user.focus_sessions
    @focus_sessions = @focus_sessions.where(task_id: params[:task_id]) if params[:task_id]
    @focus_sessions = @focus_sessions.order(started_at: :desc)
    
    render json: @focus_sessions
  end

  def show
    render json: @focus_session
  end

  def create
    @focus_session = current_user.focus_sessions.build(focus_session_params)
    @focus_session.started_at = Time.current
    
    if @focus_session.save
      render json: @focus_session, status: :created
    else
      render json: { errors: @focus_session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @focus_session.update(focus_session_params)
      render json: @focus_session
    else
      render json: { errors: @focus_session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @focus_session.destroy
    head :no_content
  end

  def stop
    @focus_session = current_user.focus_sessions.find(params[:id])
    @focus_session.ended_at = Time.current
    @focus_session.duration_minutes = ((@focus_session.ended_at - @focus_session.started_at) / 60).round
    
    if @focus_session.save
      # Update user's total focus time
      current_user.increment!(:total_focus_time, @focus_session.duration_minutes)
      render json: @focus_session
    else
      render json: { errors: @focus_session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_focus_session
    @focus_session = current_user.focus_sessions.find(params[:id])
  end

  def focus_session_params
    params.require(:focus_session).permit(:task_id, :notes)
  end
end 