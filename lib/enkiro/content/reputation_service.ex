defmodule Enkiro.Content.ReputationService do
  @moduledoc """
  A service module responsible for calculating Reputation Point (RP) values
  for all user actions across the platform. It acts as the single source of
  truth for the reward system.
  """

  @doc """
  Calculates the RP amount for a given event type.
  """
  def calculate_amount(:submit_player_report), do: 0
  def calculate_amount(:submit_bug_report), do: 0
  def calculate_amount(:submit_publication), do: 0
  def calculate_amount(:approved_player_report), do: 10
  def calculate_amount(:approved_publication), do: 15
  def calculate_amount(:receive_insightful_vote), do: 5
  # bug reports are not approved they are opened and then :reproduced
  # we shuold only award RP when they are reproduced
  def calculate_amount(:bug_report_reproduced), do: 10
  def calculate_amount(:verify_bug_report), do: 10
  def calculate_amount(:publication_upvoted), do: 2
  def calculate_amount(:report_featured), do: 100
  def calculate_amount(:publication_featured), do: 150
  def calculate_amount(:bug_report_fixed), do: 250
  def calculate_amount(:cast_insightful_vote), do: 1
  def calculate_amount(:referral_signup), do: 50
  # Commission is calculated separately
  def calculate_amount(:referral_commission), do: 0
  # RP is defined on the achievement itself
  def calculate_amount(:achievement_unlocked), do: 0
end
