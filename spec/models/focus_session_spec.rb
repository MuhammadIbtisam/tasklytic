require 'rails_helper'

RSpec.describe FocusSession, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:task) }
  end

  describe 'validations' do
    describe '#ended_at_after_started_at' do
      it 'returns error if ended at is before started at' do
        fs = build(:focus_session, started_at: 1.hour.ago, ended_at: 2.hour.ago)
        expect(fs).not_to be_valid
        expect(fs.errors[:ended_at]).to include('ended_at must be after started at...')
      end
    end
  end
end
