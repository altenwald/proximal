defmodule Proximal.State do
  @moduledoc false

  @enforce_keys [
    :handler,
    :user_state,
    :prolog,
    :expand_entity,
    :character_data_max_length,
    :cdata_as_characters
  ]

  @type t() :: %__MODULE__{
          stack: list(),
          handler: module(),
          user_state: term(),
          prolog: keyword() | nil,
          expand_entity: :keep | :never | :skip | {module(), atom(), list()},
          character_data_max_length: non_neg_integer() | :infinity,
          cdata_as_characters: boolean(),
          continuous: boolean()
        }

  defstruct [stack: [], continuous: false] ++ @enforce_keys
end
