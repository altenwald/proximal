defmodule Proximal.Prolog do
  @moduledoc """
  Represents the XML prolog declaration (version, encoding, standalone).
  """

  defstruct [
    :version,
    :encoding,
    :standalone
  ]

  @type t() :: %__MODULE__{
          version: String.t() | nil,
          encoding: atom() | String.t() | nil,
          standalone: boolean() | nil
        }

  @doc """
  Builds a `%Proximal.Prolog{}` struct from a keyword list.
  """
  @spec from_keyword(keyword()) :: t()
  def from_keyword(prolog) do
    version = Keyword.get(prolog, :version, "1.0")
    encoding = Keyword.get(prolog, :encoding)
    standalone = Keyword.get(prolog, :standalone)

    %__MODULE__{
      version: version,
      encoding: encoding,
      standalone: standalone
    }
  end
end
