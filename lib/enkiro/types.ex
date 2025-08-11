defmodule Enkiro.Types do
  @moduledoc """
  A central module for defining custom Ecto types and enums.
  """

  @doc "Returns the allowed values for the post_type enum."
  def post_type_values, do: [:player_report, :bug_report, :publication]

  def general_post_status_values,
    do: [:live, :hidden, :deleted, :pending_review]

  def player_report_status_values,
    do: general_post_status_values()

  def publication_status_values,
    do: general_post_status_values()

  def bug_report_status_values,
    do: [
      :open,
      :reproduced,
      :pending_fix,
      :pending_verification,
      :closed_fixed,
      :closed_wont_fix
    ]

  def all_post_status_values,
    do: Enum.uniq(general_post_status_values() ++ bug_report_status_values())

  @doc "Returns the allowed values for the vote_type enum."
  def vote_type_values, do: [:insightful, :upvote, :reproduced, :verified_fix]

  @doc "Returns the allowed values for the votable_type enum."
  def votable_types, do: [:post, :comment]

  def user_reputation_tier_values,
    do: [
      :observer,
      :contributor,
      :reporter,
      :analyst,
      :veteran_analyst,
      :community_pillar
    ]

  def user_subscription_tier_values, do: [:free, :analyst, :veteran]

  def rp_event_type_values,
    do: [
      # Positive Events
      :submit_player_report,
      :submit_bug_report,
      :submit_publication,
      :receive_insightful_vote,
      # When your bug is reproduced by others
      :bug_report_reproduced,
      # When you reproduce someone else's bug
      :verify_bug_report,
      :publication_upvoted,
      :report_featured,
      :publication_featured,
      :bug_report_fixed,
      :cast_insightful_vote,
      :referral_signup,
      :referral_commission,
      :achievement_unlocked,

      # Negative Events
      :report_flagged
    ]

  def rp_source_type_values,
    do: [
      :post,
      :vote,
      :achievement,
      :referral
    ]
end
