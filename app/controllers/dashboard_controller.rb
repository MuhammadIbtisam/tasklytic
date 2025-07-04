class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @stats = {
      total_projects: current_user.projects.count,
      total_tasks: current_user.tasks.count,
      completed_tasks: current_user.tasks.completed.count,
      overdue_tasks: current_user.tasks.overdue.count,
      total_focus_hours: current_user.total_focus_hours,
      tasks_due_today: current_user.tasks.due_today.count,
      tasks_due_this_week: current_user.tasks.due_this_week.count
    }

    @recent_tasks = current_user.tasks.order(created_at: :desc).limit(5)
    @overdue_tasks = current_user.tasks.overdue.limit(5)
    @recent_focus_sessions = current_user.focus_sessions.order(started_at: :desc).limit(5)

    render json: {
      stats: @stats,
      recent_tasks: @recent_tasks,
      overdue_tasks: @overdue_tasks,
      recent_focus_sessions: @recent_focus_sessions
    }
  end
end 