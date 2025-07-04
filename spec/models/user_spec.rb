require 'rails_helper'

RSpec.describe User, type: :model do
  subject { FactoryBot.create(:user) }

  describe "associations" do
    it { should have_many(:projects) }
    it { should have_many(:tasks) }
    it { should have_many(:focus_sessions) }
  end

  describe 'validations' do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe 'Devise integration' do
    context 'password validation' do
      it 'requires password confirmation' do
        user = build(:user, password_confirmation: 'different')
        expect(user).not_to be_valid
        expect(user.errors[:password_confirmation]).to include("doesn't match Password")
      end

      it 'enforces minimum password length' do
        user = build(:user, password: '123', password_confirmation: '123')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
      end

      it 'is valid with proper password and confirmation' do
        user = build(:user, password: 'password123', password_confirmation: 'password123')
        expect(user).to be_valid
      end
    end
  end

  let(:user) { create(:user, first_name: 'ibi', last_name: 'test', total_focus_time: 120) }

  describe '#full_name' do
    it 'returns the concatenated first and last name' do
      expect(user.full_name).to eq('ibi test')
    end
  end

  describe '#total_focus_hours' do
    it 'converts total_focus_time from minutes to hours' do
      expect(user.total_focus_hours).to eq(2.0)
    end

    it 'returns 0 when total_focus_time is nil' do
      user_without_focus = create(:user, total_focus_time: nil)
      expect(user_without_focus.total_focus_hours).to eq(0.0)
    end

    it 'returns 0 when total_focus_time is 0' do
      user_without_focus = create(:user, total_focus_time: 0)
      expect(user_without_focus.total_focus_hours).to eq(0.0)
    end

    it 'handles decimal hours correctly' do
      user_with_decimal = create(:user, total_focus_time: 90)
      expect(user_with_decimal.total_focus_hours).to eq(1.5)
    end
  end

  describe 'factory traits' do
    context 'with different user states' do
      it 'creates productive user with trait' do
        productive_user = create(:user, :productive)
        expect(productive_user.total_focus_hours).to be > 80
      end

      it 'creates new user with trait' do
        new_user = create(:user, :new_user)
        expect(new_user.total_focus_hours).to eq(0)
        expect(new_user.sign_in_count).to eq(1)
      end
    end
  end
end
