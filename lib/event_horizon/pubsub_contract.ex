defmodule EventHorizon.PubSubContract do
  @moduledoc """
  PubSub contract for EventHorizon.

  Defines the messages EventHorizon sends and receives when communicating
  with the Accumulator node.

  ## Direction

  EventHorizon -> Accumulator:
  - Analytics events (SiteVisit, BlogVisit, BlogLike, BlogComment)
  - Presence updates (SitePresence, BlogPresence)

  Accumulator -> EventHorizon:
  - Stats updates (SiteUpdated, BlogUpdated)
  - Presence requests (PresenceRequest)
  """

  use PubSubContract.Contract

  # Messages we send TO Accumulator
  sends(EhaPubsubMessages.Analytics.SiteVisit)
  sends(EhaPubsubMessages.Analytics.BlogVisit)
  sends(EhaPubsubMessages.Analytics.BlogLike)
  sends(EhaPubsubMessages.Analytics.BlogComment)
  sends(EhaPubsubMessages.Presence.SitePresence)
  sends(EhaPubsubMessages.Presence.BlogPresence)

  # Messages we receive FROM Accumulator
  receives(EhaPubsubMessages.Stats.SiteUpdated)
  receives(EhaPubsubMessages.Stats.BlogUpdated)
  receives(EhaPubsubMessages.Stats.Spotify.NowPlaying)
  receives(EhaPubsubMessages.Presence.PresenceRequest)
end
