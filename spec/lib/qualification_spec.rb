# frozen_string_literal: true

RSpec.describe Qualification do
  let(:user) { create(:user_with_wca_id) }
  let(:first_competition) do
    create(
      :competition,
      start_date: '2021-02-01',
      end_date: '2021-02-01',
    )
  end
  let(:second_competition) do
    create(
      :competition,
      start_date: '2021-03-01',
      end_date: '2021-03-02',
    )
  end

  let!(:first_333_result) do
    create(
      :result,
      person_id: user.wca_id,
      competition_id: first_competition.id,
      event_id: '333',
      best: 1200,
      average: 1500,
    )
  end
  let!(:second_333_result) do
    create(
      :result,
      person_id: user.wca_id,
      competition_id: second_competition.id,
      event_id: '333',
      best: 1100,
      average: 1200,
    )
  end
  let!(:first_oh_result_no_single) do
    create(
      :result,
      person_id: user.wca_id,
      competition_id: first_competition.id,
      event_id: '333oh',
      best: -1,
      average: -1,
    )
  end
  let!(:second_oh_result) do
    create(
      :result,
      person_id: user.wca_id,
      competition_id: second_competition.id,
      event_id: '333oh',
      best: 1700,
      average: 2000,
    )
  end
  let!(:first_444_result_no_average) do
    create(
      :result,
      person_id: user.wca_id,
      competition_id: first_competition.id,
      event_id: '444',
      best: 4500,
      average: -1,
    )
  end
  let!(:second_444_result) do
    create(
      :result,
      person_id: user.wca_id,
      competition_id: second_competition.id,
      event_id: '444',
      best: 4500,
      average: 4800,
    )
  end

  context "Single" do
    it "requires single" do
      input = {
        'resultType' => 'single',
        'type' => 'ranking',
        'whenDate' => '2021-06-01',
      }
      qualification = Qualification.load(input)
      expect(qualification).not_to be_valid
    end

    it "requires date" do
      input = {
        'resultType' => 'single',
        'type' => 'ranking',
        'level' => 1000,
      }
      qualification = Qualification.load(input)
      expect(qualification).not_to be_valid
    end

    it "requires type" do
      input = {
        'resultType' => 'single',
        'level' => 1000,
        'whenDate' => '2021-06-01',
      }
      qualification = Qualification.load(input)
      expect(qualification).not_to be_valid
    end

    it "parses correctly" do
      input = {
        'resultType' => 'single',
        'type' => 'attemptResult',
        'whenDate' => '2021-06-01',
        'level' => 1000,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
    end

    it "parses anyResult correctly" do
      input = {
        'resultType' => 'single',
        'type' => 'anyResult',
        'whenDate' => '2021-06-01',
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
    end

    it "requires a successful time for ranking" do
      input = {
        'resultType' => 'single',
        'type' => 'ranking',
        'whenDate' => '2021-02-15',
        'level' => 50,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '333')).to be true
      expect(qualification.can_register?(user, '333oh')).to be false

      input = {
        'resultType' => 'single',
        'type' => 'ranking',
        'whenDate' => '2021-03-15',
        'level' => 50,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '333')).to be true
      expect(qualification.can_register?(user, '333oh')).to be true
    end

    it "requires a successful time for anyResult" do
      input = {
        'resultType' => 'single',
        'type' => 'anyResult',
        'whenDate' => '2021-02-15',
        'level' => 50,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '333')).to be true
      expect(qualification.can_register?(user, '333oh')).to be false

      input = {
        'resultType' => 'single',
        'type' => 'anyResult',
        'whenDate' => '2021-03-15',
        'level' => 50,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '333')).to be true
      expect(qualification.can_register?(user, '333oh')).to be true
    end

    it "requires strictly less than for attemptResult" do
      input = {
        'resultType' => 'single',
        'type' => 'attemptResult',
        'whenDate' => '2021-02-15',
        'level' => 1200,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '333')).to be false

      input = {
        'resultType' => 'single',
        'type' => 'attemptResult',
        'whenDate' => '2021-02-15',
        'level' => 1201,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '333')).to be true
    end

    # User's qualifying result was achieved on the 2nd
    it "requires end date before" do
      # Result must be achieved by the 3rd - user qualifies because result achieved before whenDate
      input = {
        'resultType' => 'single',
        'type' => 'attemptResult',
        'whenDate' => '2021-03-03',
        'level' => 1150,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '333')).to be true

      # Result must be achieved by the 2nd - user qualifies because result achieved on whenDate
      input = {
        'resultType' => 'single',
        'type' => 'attemptResult',
        'whenDate' => '2021-03-02',
        'level' => 1150,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '333')).to be true

      # Result must be achieved by the 1st - user does not qualify because result achieved after whenDate
      input = {
        'resultType' => 'single',
        'type' => 'attemptResult',
        'whenDate' => '2021-03-01',
        'level' => 1150,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '333')).to be false
    end
  end

  context "Average" do
    it "requires average" do
      input = {
        'resultType' => 'average',
        'type' => 'attemptResult',
        'whenDate' => '2021-06-01',
      }
      qualification = Qualification.load(input)
      expect(qualification).not_to be_valid
    end

    it "requires date" do
      input = {
        'resultType' => 'average',
        'type' => 'attemptResult',
        'level' => 1000,
      }
      qualification = Qualification.load(input)
      expect(qualification).not_to be_valid
    end

    it "requires type" do
      input = {
        'resultType' => 'average',
        'level' => 1000,
        'whenDate' => '2021-06-01',
      }
      qualification = Qualification.load(input)
      expect(qualification).not_to be_valid
    end

    it "parses correctly" do
      input = {
        'resultType' => 'average',
        'type' => 'attemptResult',
        'whenDate' => '2021-06-01',
        'level' => 1000,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
    end

    it "requires a successful time for ranking" do
      input = {
        'resultType' => 'average',
        'type' => 'ranking',
        'whenDate' => '2021-02-15',
        'level' => 50,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '444')).to be false

      input = {
        'resultType' => 'average',
        'type' => 'ranking',
        'whenDate' => '2021-03-15',
        'level' => 50,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '444')).to be true
    end

    it "requires a successful time for anyResult" do
      input = {
        'resultType' => 'average',
        'type' => 'anyResult',
        'whenDate' => '2021-02-15',
        'level' => 50,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '444')).to be false

      input = {
        'resultType' => 'average',
        'type' => 'anyResult',
        'whenDate' => '2021-03-15',
        'level' => 50,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '444')).to be true
    end

    it "requires strictly less than for attemptResult" do
      input = {
        'resultType' => 'average',
        'type' => 'attemptResult',
        'whenDate' => '2021-02-15',
        'level' => 1500,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '333')).to be false

      input = {
        'resultType' => 'average',
        'type' => 'attemptResult',
        'whenDate' => '2021-02-15',
        'level' => 1501,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '333')).to be true
    end

    # User's qualifying result was achieved on the 2nd
    it "supports achieving result on qualification date" do
      # Result must be achieved by the 3rd - user qualifies because result achieved before whenDate
      input = {
        'resultType' => 'average',
        'type' => 'attemptResult',
        'whenDate' => '2021-03-03',
        'level' => 2500,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '333oh')).to be true

      # Result must be achieved by the 2nd - user qualifies because result achieved on whenDate
      input = {
        'resultType' => 'average',
        'type' => 'attemptResult',
        'whenDate' => '2021-03-02',
        'level' => 2500,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '333oh')).to be true

      # Result must be achieved by the 1st - user does not qualify because result achieved after whenDate
      input = {
        'resultType' => 'average',
        'type' => 'attemptResult',
        'whenDate' => '2021-03-01',
        'level' => 2500,
      }
      qualification = Qualification.load(input)
      expect(qualification).to be_valid
      expect(qualification.can_register?(user, '333oh')).to be false
    end
  end
end
