defmodule GymratWeb.UserIdentifierHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `user_identifier` directory for all templates available.
  """
  use GymratWeb, :html

  embed_templates "user_identifier/*"
end
