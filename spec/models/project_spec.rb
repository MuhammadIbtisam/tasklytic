require 'rails_helper'

RSpec.describe Project, type: :model do
  let(:user) { FactoryBot.create(:user) }
  subject { FactoryBot.build(:project, user: user) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:tasks).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:user_id) }

    context 'when name is invalid' do
      it 'is invalid with empty name' do
        project = build(:project, name: '')
        expect(project).not_to be_valid
        expect(project.errors[:name]).to include("can't be blank")
      end

      it 'is invalid with nil name' do
        project = build(:project, name: nil)
        expect(project).not_to be_valid
        expect(project.errors[:name]).to include("can't be blank")
      end
    end

    context 'when name uniqueness is violated' do
      it 'allows same name for different users' do
        user1 = create(:user)
        user2 = create(:user)

        create(:project, user: user1, name: 'Same Name')
        project2 = build(:project, user: user2, name: 'Same Name')

        expect(project2).to be_valid
      end

      it 'prevents duplicate names for same user' do
        create(:project, user: user, name: 'Test Project')
        duplicate = build(:project, user: user, name: 'Test Project')

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to include('has already been taken')
      end
    end
  end

  describe 'scopes' do
    context '.with_tasks' do
      it 'returns only projects with associated tasks' do
        project_with_task = create(:project)
        create(:task, project: project_with_task)
        project_without_task = create(:project)

        expect(Project.with_tasks).to include(project_with_task)
        expect(Project.with_tasks).not_to include(project_without_task)
      end

      it 'returns distinct projects when multiple tasks are associated' do
        project = create(:project)
        create(:task, project: project)
        create(:task, project: project)

        expect(Project.with_tasks.count).to eq(1)
      end

      it 'returns empty when no projects have tasks' do
        create(:project)
        create(:project)

        expect(Project.with_tasks).to be_empty
      end
    end

    context '.recent' do
      it 'returns projects ordered by created_at in descending order' do
        old_project = create(:project, created_at: 2.days.ago)
        new_project = create(:project, created_at: 1.day.ago)
        current_project = create(:project, created_at: Time.current)

        expect(Project.recent.first).to eq(current_project)
        expect(Project.recent.last).to eq(old_project)
      end

      it 'handles projects created at the same time' do
        time = Time.current
        project1 = create(:project, created_at: time)
        project2 = create(:project, created_at: time)

        recent_projects = Project.recent
        expect(recent_projects).to include(project1, project2)
      end
    end
  end

  describe '#task_count' do
    it 'returns the count of tasks associated with the project' do
      project_with_task = create(:project)
      create(:task, project: project_with_task)
      project_without_task = create(:project)

      expect(project_with_task.task_count).to eq(1)
      expect(project_without_task.task_count).to eq(0)
    end

    it 'returns 0 for new projects' do
      expect(subject.task_count).to eq(0)
    end

    it 'counts multiple tasks correctly' do
      project = create(:project)
      create_list(:task, 5, project: project)

      expect(project.task_count).to eq(5)
    end
  end

  describe '#completed_task_count' do
    it 'returns the count of completed tasks in the project' do
      project = create(:project)
      create(:task, project: project, status: :completed)
      create(:task, project: project, status: :pending)
      create(:task, project: project, status: :completed)

      expect(project.completed_task_count).to eq(2)
    end

    it 'returns 0 when no tasks are completed' do
      project = create(:project)
      create(:task, project: project, status: :pending)
      create(:task, project: project, status: :in_progress)

      expect(project.completed_task_count).to eq(0)
    end

    it 'returns 0 for projects without tasks' do
      expect(subject.completed_task_count).to eq(0)
    end
  end

  describe '#completion_percentage' do
    it 'returns 0 when there are no tasks associated with the project' do
      expect(subject.completion_percentage).to eq(0)
    end

    it 'returns 100 when all tasks are completed' do
      project = create(:project)
      create_list(:task, 3, project: project, status: :completed)

      expect(project.completion_percentage).to eq(100)
    end

    it 'returns the correct percentage of completed tasks' do
      project = create(:project)
      create(:task, project: project, status: :completed)
      create(:task, project: project, status: :pending)

      expect(project.completion_percentage).to eq(50)
    end

    it 'handles decimal percentages correctly' do
      project = create(:project)
      create_list(:task, 3, project: project, status: :completed)
      create_list(:task, 7, project: project, status: :pending)

      expect(project.completion_percentage).to eq(30)
    end
  end

  describe '#total_estimated_time' do
    it 'returns 0 if no tasks are associated' do
      expect(subject.total_estimated_time).to eq(0)
    end

    it 'returns the sum of estimated time for all tasks' do
      project = create(:project)
      create(:task, project: project, estimated_minutes: 50)
      create(:task, project: project, estimated_minutes: 30)
      create(:task, project: project, estimated_minutes: 20)

      expect(project.total_estimated_time).to eq(100)
    end

    it 'handles tasks with nil estimated_minutes' do
      project = create(:project)
      create(:task, project: project, estimated_minutes: 50)
      create(:task, project: project, estimated_minutes: nil)
      create(:task, project: project, estimated_minutes: 30)

      expect(project.total_estimated_time).to eq(80)
    end

    it 'returns 0 when all tasks have nil estimated_minutes' do
      project = create(:project)
      create_list(:task, 3, project: project, estimated_minutes: nil)

      expect(project.total_estimated_time).to eq(0)
    end
  end

  describe '#total_actual_time' do
    it 'returns 0 if there are no tasks associated' do
      expect(subject.total_actual_time).to eq(0)
    end

    it 'returns 0 if tasks have no focus sessions' do
      project = create(:project)
      create_list(:task, 3, project: project)

      expect(project.total_actual_time).to eq(0)
    end

    it 'returns the total focus time of all associated tasks' do
      project = create(:project)
      task1 = create(:task, project: project)
      task2 = create(:task, project: project)

      create(:focus_session, task: task1, duration_minutes: 30)
      create(:focus_session, task: task1, duration_minutes: 20)
      create(:focus_session, task: task2, duration_minutes: 45)

      expect(project.total_actual_time).to eq(95)
    end

    it 'handles tasks with multiple focus sessions' do
      project = create(:project)
      task = create(:task, project: project)

      create_list(:focus_session, 5, task: task, duration_minutes: 10)

      expect(project.total_actual_time).to eq(50)
    end
  end

  describe '#overdue_tasks' do
    it 'returns tasks that are overdue' do
      project = create(:project)
      overdue_task = create(:task, project: project, due_date: 1.day.ago, status: :pending)
      on_time_task = create(:task, project: project, due_date: 1.day.from_now, status: :pending)

      expect(project.tasks.overdue).to include(overdue_task)
      expect(project.tasks.overdue).not_to include(on_time_task)
    end
  end

  describe 'integration with associated models' do
    it 'destroys associated tasks when project is deleted' do
      project = create(:project)
      task = create(:task, project: project)

      expect { project.destroy }.to change { Task.count }.by(-1)
    end

    it 'does not destroy tasks from other projects' do
      project1 = create(:project)
      project2 = create(:project)
      task1 = create(:task, project: project1)
      task2 = create(:task, project: project2)

      expect { project1.destroy }.to change { Task.count }.by(-1)
      expect(Task.exists?(task2.id)).to be true
    end
  end

  describe 'factory traits' do
    context 'with different project states' do
      it 'creates project with many tasks' do
        project = create(:project, :with_many_tasks)
        expect(project.task_count).to eq(10)
      end

      it 'creates completed project' do
        project = create(:project, :completed)
        expect(project.completion_percentage).to eq(100)
      end

      it 'creates project with mixed task statuses' do
        project = create(:project, :with_mixed_tasks)
        expect(project.completion_percentage).to be_between(0, 100)
      end
    end
  end
end