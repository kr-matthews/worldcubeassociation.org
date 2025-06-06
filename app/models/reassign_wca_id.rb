# frozen_string_literal: true

class ReassignWcaId
  include ActiveModel::Model

  attr_reader :account1, :account2, :account1_user, :account2_user

  def account1=(account1)
    @account1 = account1
    @account1_user = User.find_by(id: account1)
  end

  def account2=(account2)
    @account2 = account2
    @account2_user = User.find_by(id: account2)
  end

  validates :account1, presence: true
  validates :account2, presence: true

  validate :require_valid_accounts
  def require_valid_accounts
    errors.add(:account1, "Not found") unless @account1_user
    errors.add(:account2, "Not found") unless @account2_user
  end

  validate :require_different_people
  def require_different_people
    errors.add(:account2, "Cannot transfer a WCA ID of an account with itself!") if account1_user && account2_user && account1 == account2
  end

  validate :require_valid_wca_ids
  def require_valid_wca_ids
    account1_wca_id = @account1_user&.wca_id
    account2_wca_id = @account2_user&.wca_id
    errors.add(:account1, "Account 1 must have a WCA ID assigned") unless account1_wca_id
    errors.add(:account2, "Account 2 must not have a WCA ID assigned") if account2_wca_id
  end

  validate :must_look_like_the_same_person
  def must_look_like_the_same_person
    return unless account1_user && account2_user

    errors.add(:account2, "Names don't match") unless account1_user.name == account2_user.name
    errors.add(:account2, "Countries don't match") unless account1_user.country_iso2 == account2_user.country_iso2
    errors.add(:account2, "Genders don't match") unless account1_user.gender == account2_user.gender
    errors.add(:account2, "Birthdays don't match") unless account1_user.dob == account2_user.dob
  end

  def do_reassign_wca_id
    return false unless valid?

    ActiveRecord::Base.transaction do
      # Update Organized Competitions
      CompetitionOrganizer.where(organizer_id: account1_user.id).update_all(organizer_id: account2_user.id)

      # Update Delegated Competitions
      CompetitionDelegate.where(delegate_id: account1_user.id).update_all(delegate_id: account2_user.id)

      # Update Competitions Results Posted By
      Competition.where(results_posted_by: account1_user.id).update_all(results_posted_by: account2_user.id)

      # Update Competitions Announced By
      Competition.where(announced_by: account1_user.id).update_all(announced_by: account2_user.id)

      # Update roles
      UserRole.where(user_id: account1_user.id).update_all(user_id: account2_user.id)

      # Update WCA ID
      wca_id = account1_user.wca_id
      User.where(id: account1_user.id).update_all(wca_id: nil) # Must remove WCA ID before adding it as it is unique in the Users table
      User.where(id: account2_user.id).update_all(wca_id: wca_id)
    end

    true
  end
end
