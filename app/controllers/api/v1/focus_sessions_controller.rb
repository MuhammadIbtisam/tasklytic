module Api
  module V1
    class FocusSessionsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_focus_session, only: [:show, :update, :destroy, :stop]

      def index
        page = params[:page].to_i
        unless page.positive?
          return render json: { error: 'page parameter must be positive integer' }, status: :bad_request
        end

        per_page = [params[:per_page]&.to_i || 10, 50].min
        focus_sessions = current_user.focus_sessions

        # Filter by task_id if provided
        if params[:task_id].present?
          focus_sessions = focus_sessions.where(task_id: params[:task_id])
        end

        # Filter by date range if provided
        if params[:start_date].present?
          focus_sessions = focus_sessions.where('started_at >= ?', Date.parse(params[:start_date]).beginning_of_day)
        end

        if params[:end_date].present?
          focus_sessions = focus_sessions.where('started_at <= ?', Date.parse(params[:end_date]).end_of_day)
        end

        # Filter by status (active/completed)
        if params[:status].present?
          case params[:status]
          when 'active'
            focus_sessions = focus_sessions.where(ended_at: nil)
          when 'completed'
            focus_sessions = focus_sessions.where.not(ended_at: nil)
          end
        end

        focus_sessions = focus_sessions.order(started_at: :desc).page(page).per(per_page)

        render json: {
          focus_sessions: focus_sessions,
          meta: {
            page: focus_sessions.current_page,
            per_page: focus_sessions.limit_value,
            total: focus_sessions.total_count,
            total_pages: focus_sessions.total_pages
          }
        }, status: :ok
      end

      def show
        render json: @focus_session, status: :ok
      end

      def create
        focus_session = current_user.focus_sessions.build(focus_session_params)
        focus_session.started_at = Time.current

        if focus_session.save
          render json: focus_session, status: :created
        else
          render json: { errors: focus_session.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @focus_session.update(focus_session_params)
          render json: @focus_session, status: :ok
        else
          render json: { errors: @focus_session.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @focus_session.destroy
        head :no_content
      end

      def stop
        if @focus_session.ended_at.present?
          return render json: { error: 'Focus session already ended' }, status: :unprocessable_entity
        end

        @focus_session.ended_at = Time.current
        @focus_session.duration_minutes = ((@focus_session.ended_at - @focus_session.started_at) / 60).round

        if @focus_session.save
          # Update user's total focus time
          current_user.increment!(:total_focus_time, @focus_session.duration_minutes)
          render json: @focus_session, status: :ok
        else
          render json: { errors: @focus_session.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Get current active focus session
      def current
        active_session = current_user.focus_sessions.find_by(ended_at: nil)
        
        if active_session
          render json: active_session, status: :ok
        else
          render json: { message: 'No active focus session' }, status: :not_found
        end
      end

      # Get focus session statistics
      def stats
        start_date = params[:start_date]&.to_date || 1.week.ago.to_date
        end_date = params[:end_date]&.to_date || Date.current

        focus_sessions = current_user.focus_sessions
          .where(started_at: start_date.beginning_of_day..end_date.end_of_day)
          .where.not(ended_at: nil)

        total_duration = focus_sessions.sum(:duration_minutes)
        total_sessions = focus_sessions.count
        average_duration = total_sessions > 0 ? (total_duration.to_f / total_sessions).round(1) : 0

        # Daily breakdown
        daily_stats = focus_sessions.group_by { |fs| fs.started_at.to_date }
          .transform_values { |sessions| sessions.sum(&:duration_minutes) }

        # Task breakdown
        task_stats = focus_sessions.joins(:task)
          .group('tasks.title')
          .sum(:duration_minutes)

        render json: {
          period: {
            start_date: start_date,
            end_date: end_date
          },
          total_duration_minutes: total_duration,
          total_duration_hours: (total_duration / 60.0).round(2),
          total_sessions: total_sessions,
          average_duration_minutes: average_duration,
          daily_breakdown: daily_stats,
          task_breakdown: task_stats
        }, status: :ok
      end

      private

      def set_focus_session
        @focus_session = current_user.focus_sessions.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Focus session not found' }, status: :not_found
      end

      def focus_session_params
        params.require(:focus_session).permit(:task_id, :notes)
      end
    end
  end
end
